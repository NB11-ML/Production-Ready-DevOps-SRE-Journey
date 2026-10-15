## SRE Incident Report: EKS Gateway Connectivity and TLS Certificate Troubleshooting

### Incident Summary
| Field | Details |
| :--- | :--- |
| **Project** | AI-BankApp — GitOps CI/CD |
| **Environment** | Amazon EKS, AWS us-west-2 |
| **Kubernetes ingress** | Envoy Gateway / Gateway API |
| **GitOps controller** | ArgoCD |
| **Certificate manager** | cert-manager / Let's Encrypt |
| **Severity** | Development-environment connectivity incident |
| **Initial symptom** | HTTP connection timeout and ACME HTTP-01 validation failure |
| **Final status** | Resolved — HTTPS and certificate validation verified |

---

### 1. Problem Statement

While configuring the GitOps project under Task 2, the application was deployed successfully on Amazon EKS, but external connectivity and TLS certificate provisioning were inconsistent.

The initial HTTP request to the hostname timed out:
```bash
curl: (28) Failed to connect to 52.43.73.130.nip.io port 80
after 5002 ms: Timeout was reached

```

ArgoCD initially reported the Gateway, HTTPRoute, and Certificate resources as degraded or progressing.

The investigation identified multiple related configuration issues: an incorrect or stale hostname/IP association, a mismatch between the Gateway and certificate configuration during hostname changes, and uncertainty about the AWS load balancer security-group traffic path.

---

### 2. Investigation and Root Cause Analysis

#### Step 1: Investigated AWS load balancer resources

* The `ELBv2` query returned no matching load balancer ARN because the Gateway was backed by a Classic Load Balancer (ELB) rather than an ELBv2 Application or Network Load Balancer.
* The legacy AWS CLI command successfully returned the load balancers:
```bash
aws elb describe-load-balancers \
  --region us-west-2 \
  --query 'LoadBalancerDescriptions[*].[LoadBalancerName,DNSName,Scheme,SecurityGroups,ListenerDescriptions[*].Listener]' \
  --output yaml

```


* Two internet-facing Classic Load Balancers were present. The relevant Gateway service used:
`abab413936f6e495aa0d98f181b3a65f-552190864.us-west-2.elb.amazonaws.com`
* Its listener exposed port 80 and forwarded traffic to NodePort `31149`.
* **Finding:** The original lookup failed because the wrong AWS API family was used. Classic ELBs must be queried using `aws elb`, while ALBs and NLBs are queried using `aws elbv2`.

#### Step 2: Verified DNS and external connectivity

* The original hostname resolved to `52.43.73.130`, but direct HTTP requests to that address timed out.
* The Gateway's actual address was obtained from Kubernetes:
```bash
kubectl get gateway bankapp-gateway -n bankapp \
  -o jsonpath='{.status.addresses[*].value}{"\n"}'

```


* The Gateway service was also checked:
```bash
kubectl get svc envoy-bankapp-bankapp-gateway-1a1eb035 \
  -n envoy-gateway-system -o wide

```


* The ELB DNS name resolved to `54.201.97.254`, and direct connectivity to that address succeeded.
* **Finding:** The working endpoint was associated with `54.201.97.254`, not the original `52.43.73.130` endpoint. The successful direct-IP request established that the ELB was reachable, but the HTTP `404` response by itself did not establish an application failure: the request used an IP-based Host header that did not necessarily match any configured HTTPRoute hostname.

#### Step 3: Validated the security-group traffic path

* The investigation inspected the relevant security-group rules and added an ingress rule allowing TCP traffic on NodePort `31149` from the Gateway load balancer's security group:
```bash
aws ec2 authorize-security-group-ingress \
  --region us-west-2 \
  --group-id sg-07ec6e505f4bff6d3 \
  --protocol tcp \
  --port 31149 \
  --source-group sg-0f2bb4dea225864ec

```


* AWS accepted the rule.
* **Finding:** The NodePort rule addressed one possible restriction in the load balancer-to-node traffic path. The available evidence does not prove that this rule alone caused the original timeout; the subsequent successful tests also depended on using the working endpoint and matching hostname.

#### Step 4: Identified inconsistent hostnames

* The Kubernetes configuration initially contained different hostname values:
* Gateway listener: `52.43.73.130.nip.io`
* HTTPRoute: `52.43.73.130.nip.io`
* Certificate DNS name: initially `52.43.73.130.nip.io`


* The endpoint was then changed to `54.201.97.254.nip.io` in the Gateway and certificate manifests. The application route also had to match the new hostname.
* The configuration was checked with:
```bash
grep -R -n \
  '52.43.73.130.nip.io\|54.201.97.254.nip.io' \
  k8s/

```


* The corrected hostname was committed to Git and pushed:
```bash
git add k8s/certificate.yml k8s/gateway.yml
git commit -m "Update BankApp hostname for TLS"
git push origin feat/gitops

```


* **Commit:** `b337b1d Update BankApp hostname for TLS`
* ArgoCD was then synchronized:
```bash
argocd app sync bankapp

```


* **Finding:** The Gateway listener, HTTPRoute, and certificate must use a consistent hostname. A stale hostname in any one of these resources can cause routing mismatches or prevent the requested certificate from being used as intended.

#### Step 5: Investigated the ACME HTTP-01 challenge

* The cert-manager solver HTTPRoute showed:
```yaml
hostnames:
  - 52.43.73.130.nip.io

```


* Its status reported:
* `Accepted: True`
* `ResolvedRefs: True`


* This indicated that the solver route was accepted and its backend references were resolved. However, those conditions did not prove that Let's Encrypt could reach the solver through the public endpoint.
* A request to the old hostname had redirected to the application's `/login` endpoint:
```http
HTTP/1.1 302 Found
location: [http://52.43.73.130.nip.io/login](http://52.43.73.130.nip.io/login)

```


* This was consistent with the request reaching the application route rather than receiving the expected ACME challenge response.
* **Finding:** ACME HTTP-01 validation requires the exact challenge path to reach the cert-manager solver. A redirect to the application login page is not a successful challenge response.

#### Step 6: Verified certificate issuance and HTTPS

* The final endpoint was tested using:
```bash
curl -I --connect-timeout 5 \
  [http://54.201.97.254.nip.io/](http://54.201.97.254.nip.io/)

```


* The application returned:
```http
HTTP/1.1 302 Found
location: [http://54.201.97.254.nip.io/login](http://54.201.97.254.nip.io/login)

```


* The HTTPS endpoint was tested with:
```bash
curl -Iv --connect-timeout 5 \
  [https://54.201.97.254.nip.io/](https://54.201.97.254.nip.io/)

```


* The response showed:
```text
SSL connection using TLSv1.3
subject: CN=54.201.97.254.nip.io
subjectAltName: host "54.201.97.254.nip.io" matched cert's "54.201.97.254.nip.io"
issuer: C=US; O=Let's Encrypt; CN=YR2
SSL certificate verify ok.

```


* The application redirected HTTPS requests to the HTTPS login page:
```http
HTTP/2 302
location: [https://54.201.97.254.nip.io/login](https://54.201.97.254.nip.io/login)

```


* **Finding:** The certificate was trusted, its hostname matched the request, and HTTPS requests reached the application. The HTTP `302` response was expected application behavior, not a TLS failure.

---

### 3. Final Verification

The final ArgoCD status showed:

```text
Name:        argocd/bankapp
Sync Status: Synced to feat/gitops (b337b1d)
Health Status: Healthy

```

The following resources were `Healthy`:

* `bankapp-gateway`
* `bankapp-route`
* `bankapp-cert`
* `bankapp` Deployment
* `mysql` Deployment
* `ollama` Deployment

---

### 4. Root Cause and Contributing Factors

The incident involved several related issues rather than one conclusively isolated fault:

1. **AWS API mismatch:** The initial `ELBv2` lookup returned no ARN because the Gateway used a Classic Load Balancer.
2. **Stale endpoint:** The original hostname resolved to an IP address that timed out, while the Gateway's current endpoint was reachable at a different IP.
3. **Hostname inconsistency:** The Gateway, HTTPRoute, certificate, and temporary ACME solver route did not all use the same hostname during the transition.
4. **Network-path uncertainty:** A NodePort security-group rule was added, but the available evidence does not establish that it was the sole cause of the timeout.
5. **ACME challenge routing:** The old hostname redirected a challenge request to `/login` instead of returning the solver response.

---

### 5. Corrective Actions

* Identified the actual load balancer and queried it with the appropriate AWS CLI.
* Retrieved the current Gateway address from Kubernetes rather than relying on an old IP.
* Inspected the AWS security-group rules for the load balancer-to-node traffic path.
* Updated the hostname in Git-managed Gateway and certificate manifests.
* Confirmed that the HTTPRoute used the corrected hostname.
* Pushed the change to `feat/gitops` and synchronized the application through ArgoCD.
* Verified the final endpoint using `curl`, including TLS certificate validation.

---

### 6. SRE Lessons Learned

* **Observe before changing:** Use Kubernetes status, AWS load balancer metadata, DNS resolution, and network tests to isolate the failing layer.
* **Validate the entire request path:** DNS → ELB listener → security groups → NodePort → Envoy Gateway → HTTPRoute → application.
* **Keep desired state consistent:** Git-managed hostnames must match across the Gateway, HTTPRoute, and certificate.
* **Treat ACME as an end-to-end test:** An accepted solver route does not guarantee that the public HTTP-01 challenge is reachable.
* **Use application-level evidence:** A `302` to `/login` demonstrates that the application is responding; it does not, by itself, demonstrate that the ACME challenge is working.
* **Verify reconciliation:** A successful `argocd app sync` is not enough on its own. Check the final health state and test the real endpoint.

---

### Final Incident Status

**Resolved.** The application was accessible over HTTPS, the Let's Encrypt certificate validated successfully, and ArgoCD reported the application as `Healthy`. The incident was resolved before proceeding to Task 3 of the Day 86 GitOps CI/CD exercise.
