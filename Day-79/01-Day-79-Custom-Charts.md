# Day 79 -- Creating a Custom Helm Chart for AI-BankApp

## Task Overview

Yesterday you deployed MySQL with a community Helm chart. Today you build a custom Helm chart for the AI-BankApp itself — converting the 12 raw YAML files from the `k8s/` directory into a templated, configurable, reusable Helm chart.

The AI-BankApp has three services: the Spring Boot banking app, a MySQL database, and an Ollama AI chatbot. By the end of today, all of this will be deployable with a single `helm install` command.

## What, Why and How Section

### 🎯 The "What": What are we actually doing?

  Imagine you are filling out paperwork to buy a house. Right now, you have 12 separate pieces of paper       (your raw `k8s/` YAML files). On every single page, you have to write your name, your address, and the      date by hand.

  Today, we are turning those 12 static pages into a **smart, digital form** (a Helm Chart).

  Instead of 12 separate files, we are creating one single package. In this package, there is a master        "Control Panel" (`values.yaml`). You type your name and address into the Control Panel just once, and the   smart form automatically fills it in across all 12 pages for you.

### 🤔 The "Why": Why go through this effort?

In the real world of DevOps and Site Reliability Engineering, you don't just deploy an app once. You deploy it to a "Testing" environment, a "Staging" environment, and a "Production" environment.

**The Problem with our old way (Raw YAML):**

* **Hardcoded mess:** The database password or the app version was typed directly into the code. To change it, you had to hunt it down.
* **Duplication:** To deploy a "Testing" version and a "Production" version, you would have to duplicate all 12 files and manually change the settings in both sets.
* **Errors:** Manually applying 12 files one by one with `kubectl apply` is risky. What if you forget one file? What if the database starts before the secret is created?

**The Solution with Helm:**

* **One Command:** We can deploy all 12 resources at once with a single command: `helm install`.
* **Highly Reusable:** Want a "Testing" environment? Just change the replica count from `4` to `1` in the Control Panel, and Helm does the rest. No need to touch the actual code.
* **Toggle Features:** Don't want the Ollama AI chatbot for a quick test? Just flip `ollama.enabled: false` in the Control Panel, and Helm completely ignores the Ollama files.

### 🛠️ The "How": How are we building this?

We are doing this in four logical steps today:

**Step 1: Build the empty box (Scaffolding)**
We use the `helm create` command to generate empty folders. This gives us the standard folder structure that Helm expects to see.

**Step 2: Create the Master Control Panel (`values.yaml`)**
We look at our old 12 files, find all the things that might change in the future (like passwords, memory limits, image tags, and replicas), and put them into one central `values.yaml` file.

**Step 3: Create the "Mad Libs" Templates**
We take the original 12 YAML files and move them into the `templates/` folder. But we erase the hardcoded stuff.

* *Old way:* `replicas: 4`
* *New way:* `replicas: {{ .Values.bankapp.replicaCount }}`
This weird `{{ }}` syntax is just a placeholder. It tells Helm, *"Hey, look at the values.yaml file and paste whatever number is in there."*

**Step 4: Launch it!**
Once our templates have their placeholders and our `values.yaml` has the real data, we run `helm install`. Helm mashes the templates and the values together in memory, generates the final Kubernetes instructions, and ships the whole app to your cluster in one swift move!

## File Structure

```text
AI-BankApp-DevOps/
├── k8s/                                <-- (The original 12 raw YAML files stay here)
│   ├── bankapp-deployment.yml
│   ├── configmap.yml
│   ├── ... (other files)
│
└── helm-chart/                         <-- (The folder you created in Task 1)
    └── bankapp/                        <-- (Created by 'helm create bankapp')
        ├── Chart.yaml                  <-- (Chart metadata you edited in Task 2)
        ├── values.yaml                 <-- (All the variables you defined in Task 2)
        ├── charts/                     <-- (Created by Helm, keep it empty)
        └── templates/                  <-- (Where you convert raw YAML to Helm templates)
            ├── _helpers.tpl            <-- (Keep this default file)
            ├── NOTES.txt               <-- (Keep this default file)
            ├── configmap.yaml          <-- (Task 3)
            ├── secrets.yaml            <-- (Task 3)
            ├── storage.yaml            <-- (Task 3)
            ├── bankapp-deployment.yaml <-- (Task 4)
            ├── mysql-deployment.yaml   <-- (Task 4)
            ├── ollama-deployment.yaml  <-- (Task 4)
            ├── services.yaml           <-- (Task 5)
            └── hpa.yaml                <-- (Task 5)
```

---

### Task 1: Scaffold the Chart and Study the Raw Manifests

Make sure you have the AI-BankApp repo cloned:
```bash
cd AI-BankApp-DevOps

```

Study the raw manifests you are converting:

```bash
ls k8s/

```

**Map each file to what it does:**

| File | Purpose |
| --- | --- |
| `namespace.yml` | Creates bankapp namespace |
| `configmap.yml` | MySQL host, port, database, Ollama URL |
| `secrets.yml` | MySQL credentials (base64 encoded) |
| `pv.yml` | StorageClass (gp3 via EBS CSI) |
| `pvc.yml` | PVCs for MySQL (5Gi) and Ollama (10Gi) |
| `bankapp-deployment.yml` | BankApp with init containers, probes, envFrom |
| `mysql-deployment.yml` | MySQL with EBS volume mount, probes |
| `ollama-deployment.yml` | Ollama with postStart model pull, probes |
| `service.yml` | ClusterIP services for all 3 components |
| `hpa.yml` | HPA for BankApp (2-4 replicas, 70% CPU) |
| `gateway.yml` | Envoy Gateway + HTTPRoute + TLS |
| `cert-manager.yml` | Let's Encrypt ClusterIssuer |

Now scaffold a Helm chart:

```bash
mkdir helm-chart && cd helm-chart
helm create bankapp

```

<img width="1810" height="814" alt="image" src="https://github.com/user-attachments/assets/606a3674-dd43-42ec-aceb-bc6954fd5855" />

Delete the generated template files (you will write your own from the raw manifests):

```bash
rm -rf bankapp/templates/*.yaml bankapp/templates/tests/

```
<img width="1792" height="522" alt="image" src="https://github.com/user-attachments/assets/ec18fbf7-4677-46f7-990c-cf5fa066b7bb" />

*(Keep `_helpers.tpl` and `NOTES.txt` — you will customize them).*

---

### Task 2: Define Chart.yaml and values.yaml

Edit `bankapp/Chart.yaml`:

```yaml
apiVersion: v2
name: bankapp
description: AI-BankApp -- Spring Boot banking application with MySQL and Ollama AI chatbot
type: application
version: 0.1.0
appVersion: "1.0.0"
maintainers:
  - name: NB11-ML
    url: https://github.com/NB11-ML/Production-Ready-DevOps-SRE-Journey
keywords:
  - bankapp
  - spring-boot
  - mysql
  - ollama
  - ai

```

Now create `bankapp/values.yaml` (extracting every hardcoded value into configurable values):

```yaml
# BankApp configuration
bankapp:
  replicaCount: 4
  image:
    repository: trainwithshubham/ai-bankapp-eks
    tag: "latest"
    pullPolicy: Always
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  service:
    type: ClusterIP
    port: 8080
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 4
    targetCPUUtilization: 70

# MySQL configuration
mysql:
  enabled: true
  image:
    repository: mysql
    tag: "8.0"
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  persistence:
    size: 5Gi
    storageClass: gp3

# Ollama AI configuration
ollama:
  enabled: true
  image:
    repository: ollama/ollama
    tag: "latest"
  model: tinyllama
  resources:
    requests:
      memory: "2Gi"
      cpu: "900m"
    limits:
      memory: "2.5Gi"
      cpu: "1500m"
  persistence:
    size: 10Gi
    storageClass: gp3

# Shared configuration
config:
  mysqlDatabase: bankappdb
  ollamaUrl: ""  # Auto-generated from service name if empty

# Secrets
secrets:
  mysqlRootPassword: Test@123
  mysqlUser: root
  mysqlPassword: Test@123

# Storage
storageClass:
  create: true
  name: gp3
  provisioner: ebs.csi.aws.com

# Gateway (optional -- for EKS with Envoy Gateway)
gateway:
  enabled: false
  hostname: ""
  tls:
    enabled: false

```
<img width="1802" height="528" alt="image" src="https://github.com/user-attachments/assets/04f1c60d-a6bd-41a0-ab0b-3fdaec2e0861" />

*Compare: The raw `k8s/secrets.yml` has base64-encoded credentials hardcoded. The Helm chart uses `values.yaml` and templates the Secret, so each environment can override credentials without editing YAML.*

---

### Task 3: Write the Core Templates

Convert the raw manifests into Helm templates. Each template uses `{{ .Values }}` instead of hardcoded values.

`bankapp/templates/configmap.yaml` (from `k8s/configmap.yml`):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "bankapp.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
data:
  MYSQL_HOST: {{ include "bankapp.fullname" . }}-mysql
  MYSQL_PORT: "3306"
  MYSQL_DATABASE: {{ .Values.config.mysqlDatabase | quote }}
  OLLAMA_URL: {{ default (printf "http://%s-ollama:11434" (include "bankapp.fullname" .)) .Values.config.ollamaUrl | quote }}
  SERVER_FORWARD_HEADERS_STRATEGY: "native"

```

`bankapp/templates/secrets.yaml` (from `k8s/secrets.yml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "bankapp.fullname" . }}-secret
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: {{ .Values.secrets.mysqlRootPassword | b64enc | quote }}
  MYSQL_USER: {{ .Values.secrets.mysqlUser | b64enc | quote }}
  MYSQL_PASSWORD: {{ .Values.secrets.mysqlPassword | b64enc | quote }}

```

**Deep Dive: How Helm Handles Secrets**
Helm completely ignores the old `k8s/secrets.yml` file. Instead, it acts as a translation engine that bridges your `values.yaml` file and the Kubernetes cluster dynamically:

1. **Fetch:** Helm reads `values.yaml` and grabs the plain-text string (e.g., `Test@123`).
2. **Encode:** It pushes that string through the pipe (`|`) into the `b64enc` function, instantly converting it into a Base64 string in memory (e.g., `VGVzdEAxMjM=`).
3. **Quote:** It wraps the result in quotes to ensure valid YAML formatting.
4. **Inject:** Helm sends the fully encoded Secret directly to the Kubernetes API without ever saving the Base64 string to a local file.

**🚨 Production Security Note:**
For this local learning lab, putting plain-text passwords in `values.yaml` is safe and eliminates manual Base64 encoding. However, **in a real production environment, committing plain-text passwords to a Git repository is a major security violation.**

Site Reliability Engineers handle real-world Helm secrets by:

* **CI/CD Injection:** Leaving passwords blank in `values.yaml` and injecting them dynamically at runtime via a secure pipeline (e.g., `helm install --set secrets.mysqlRootPassword=$HIDDEN_PIPELINE_VARIABLE`).
* **External Secret Managers:** Using tools like AWS Secrets Manager, HashiCorp Vault, or the External Secrets Operator to fetch passwords securely at runtime, ensuring they never touch a GitHub repository or a Helm chart.

`bankapp/templates/storage.yaml` (from `k8s/pv.yml` + `k8s/pvc.yml`):

```yaml
{{- if .Values.storageClass.create }}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: {{ .Values.storageClass.name }}
provisioner: {{ .Values.storageClass.provisioner }}
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
{{- end }}
---
{{- if .Values.mysql.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  storageClassName: {{ .Values.mysql.persistence.storageClass }}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.mysql.persistence.size }}
{{- end }}
---
{{- if .Values.ollama.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  storageClassName: {{ .Values.ollama.persistence.storageClass }}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.ollama.persistence.size }}
{{- end }}

```


---

### Task 4: Write the Deployment Templates

`bankapp/templates/bankapp-deployment.yaml` (from `k8s/bankapp-deployment.yml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.bankapp.autoscaling.enabled }}
  replicas: {{ .Values.bankapp.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}
    spec:
      initContainers:
        - name: wait-for-mysql
          image: busybox:1.36
          command: ["/bin/sh", "-c", "until nc -z {{ include "bankapp.fullname" . }}-mysql 3306; do sleep 2; done"]
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
        {{- if .Values.ollama.enabled }}
        - name: wait-for-ollama
          image: busybox:1.36
          command: ["/bin/sh", "-c", "until nc -z {{ include "bankapp.fullname" . }}-ollama 11434; do sleep 2; done"]
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
        {{- end }}
      containers:
        - name: bankapp
          image: "{{ .Values.bankapp.image.repository }}:{{ .Values.bankapp.image.tag }}"
          imagePullPolicy: {{ .Values.bankapp.image.pullPolicy }}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: {{ include "bankapp.fullname" . }}-config
            - secretRef:
                name: {{ include "bankapp.fullname" . }}-secret
          {{- with .Values.bankapp.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            failureThreshold: 15
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 5

```

**Key template decisions:**

* Init containers dynamically reference the MySQL and Ollama service names.
* Ollama init container is conditional (`{{- if .Values.ollama.enabled }}`).
* `replicas` is omitted when HPA is enabled.

`bankapp/templates/mysql-deployment.yaml` (from `k8s/mysql-deployment.yml`):

```yaml
{{- if .Values.mysql.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}-mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}-mysql
    spec:
      containers:
        - name: mysql
          image: "{{ .Values.mysql.image.repository }}:{{ .Values.mysql.image.tag }}"
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "bankapp.fullname" . }}-secret
                  key: MYSQL_ROOT_PASSWORD
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: {{ include "bankapp.fullname" . }}-config
                  key: MYSQL_DATABASE
          {{- with .Values.mysql.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql
          readinessProbe:
            exec:
              command: ["mysqladmin", "ping", "-h", "localhost"]
            initialDelaySeconds: 15
            failureThreshold: 10
          livenessProbe:
            exec:
              command: ["mysqladmin", "ping", "-h", "localhost"]
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 5
      volumes:
        - name: mysql-storage
          persistentVolumeClaim:
            claimName: {{ include "bankapp.fullname" . }}-mysql-pvc
{{- end }}

```

`bankapp/templates/ollama-deployment.yaml` (from `k8s/ollama-deployment.yml`):

```yaml
{{- if .Values.ollama.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}-ollama
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}-ollama
    spec:
      containers:
        - name: ollama
          image: "{{ .Values.ollama.image.repository }}:{{ .Values.ollama.image.tag }}"
          ports:
            - containerPort: 11434
          {{- with .Values.ollama.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: ollama-storage
              mountPath: /root/.ollama
          lifecycle:
            postStart:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - |
                    until ollama list > /dev/null 2>&1; do sleep 2; done
                    ollama pull {{ .Values.ollama.model }}
          readinessProbe:
            exec:
              command: ["/bin/sh", "-c", "ollama list | grep -q {{ .Values.ollama.model }}"]
            initialDelaySeconds: 30
            failureThreshold: 30
          livenessProbe:
            httpGet:
              path: /
              port: 11434
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 5
      volumes:
        - name: ollama-storage
          persistentVolumeClaim:
            claimName: {{ include "bankapp.fullname" . }}-ollama-pvc
{{- end }}

```

*Notice: the Ollama model name (`tinyllama`) is now a value (`{{ .Values.ollama.model }}`). You can switch models without editing YAML.*

---

### Task 5: Write the Services and HPA Templates

`bankapp/templates/services.yaml` (from `k8s/service.yml`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ include "bankapp.fullname" . }}-mysql
  ports:
    - port: 3306
---
{{- if .Values.ollama.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ include "bankapp.fullname" . }}-ollama
  ports:
    - port: 11434
{{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-service
  namespace: {{ .Release.Namespace }}
spec:
  type: {{ .Values.bankapp.service.type }}
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  selector:
    app: {{ include "bankapp.fullname" . }}
  ports:
    - port: {{ .Values.bankapp.service.port }}
      targetPort: 8080

```

`bankapp/templates/hpa.yaml` (from `k8s/hpa.yml`):

```yaml
{{- if .Values.bankapp.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "bankapp.fullname" . }}-hpa
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "bankapp.fullname" . }}
  minReplicas: {{ .Values.bankapp.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.bankapp.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.bankapp.autoscaling.targetCPUUtilization }}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
{{- end }}

```

### Task 5.5: Customize NOTES.txt (Fixing Lint Errors)

When you run `helm create`, Helm generates a default `NOTES.txt` file that tries to read routing configurations (like `ingress` or `httpRoute`). Since we removed those from our custom `values.yaml`, leaving the default file will cause a `nil pointer` error during `helm lint`.

Update `bankapp/templates/NOTES.txt` to provide specific, dynamic instructions for our AI-BankApp:

```text
Thank you for installing {{ .Chart.Name }}.

Your release is named {{ .Release.Name }} and is deployed in the {{ .Release.Namespace }} namespace.

🚀 To access the AI-BankApp frontend:
  1. Wait for all pods to be in the 'Running' state:
     kubectl get pods --namespace {{ .Release.Namespace }} -w

  2. Port-forward the bankapp service to your local machine:
     kubectl port-forward svc/{{ include "bankapp.fullname" . }}-service --namespace {{ .Release.Namespace }} 8080:8080

  3. Open your browser and visit:
     http://localhost:8080

{{- if .Values.mysql.enabled }}
🐬 MySQL is enabled and running internally.
{{- end }}

{{- if .Values.ollama.enabled }}
🤖 Ollama AI Chatbot is enabled. Note: It may take a few minutes for the container to pull the {{ .Values.ollama.model }} model before becoming ready.
{{- end }}

```
---

### Task 6: Validate and Deploy

Lint the chart:

```bash
helm lint bankapp/

```

Render templates locally (see the final YAML without deploying):

```bash
helm template my-bankapp bankapp/

```
<img width="1854" height="1226" alt="image" src="https://github.com/user-attachments/assets/f261c339-61ae-42c4-9a9d-3c881665b78a" />


*(Review the output. Every `{{ }}` should be resolved to actual values).*

Render with overrides:

```bash
helm template my-bankapp bankapp/ \
  --set bankapp.image.tag=abc1234 \
  --set bankapp.replicaCount=2 \
  --set ollama.enabled=false

```

<img width="1808" height="1154" alt="image" src="https://github.com/user-attachments/assets/f9386b4e-8d15-48b4-aef4-84ba66557aaf" />


*Notice: setting `ollama.enabled=false` removes the Ollama Deployment, Service, PVC, and the init container from the BankApp. One boolean controls an entire component.*

Dry run against the cluster:

```bash
helm install my-bankapp bankapp/ --dry-run --debug -n bankapp --create-namespace

```
<img width="1804" height="1234" alt="image" src="https://github.com/user-attachments/assets/864403b4-7ef4-463f-a173-a4cf95b150eb" />


Deploy for real (on Kind — skip StorageClass creation since Kind uses its own):

```bash
helm install my-bankapp bankapp/ \
  -n bankapp --create-namespace \
  --set storageClass.create=false \
  --set mysql.persistence.storageClass=standard \
  --set ollama.persistence.storageClass=standard

```
<img width="2474" height="1186" alt="image" src="https://github.com/user-attachments/assets/6094e62c-2190-4e38-af26-b4e088f0004e" />


Verify:

```bash
helm list -n bankapp
kubectl get all -n bankapp
kubectl get pvc -n bankapp
kubectl get configmap,secret -n bankapp

```

<img width="3010" height="1588" alt="image" src="https://github.com/user-attachments/assets/627b0111-9a97-420e-9b15-043304eb0de8" />


Wait for all pods to be ready (Ollama takes time to pull the model):

```bash
kubectl get pods -n bankapp -w

```

<img width="1694" height="414" alt="image" src="https://github.com/user-attachments/assets/e2733071-f465-426c-b881-ae37713f84da" />


Access the app:

```bash
kubectl port-forward svc/my-bankapp-service -n bankapp 8080:8080

```

<img width="1862" height="528" alt="image" src="https://github.com/user-attachments/assets/53c7c7a5-4cc3-49de-a028-d4fbbcc54257" />


*(Open http://localhost:8080 — you should see the AI-BankApp login page. Compare: 12 raw YAML files vs 1 Helm command. Same result, but now configurable, versionable, and rollback-safe).*

Clean up:

```bash
helm uninstall my-bankapp -n bankapp

```
<img width="1618" height="1880" alt="image" src="https://github.com/user-attachments/assets/c6cd964b-84cf-4435-9d33-f6dcc364f608" />


---

### 🛠️ Troubleshooting & SRE Notes: Handling ARM64 Architecture Mismatches

If you are running a local Kubernetes cluster (like KinD or Minikube) on an Apple Silicon Mac (M1/M2/M3) or any ARM64 architecture, you will likely encounter an `ErrImagePull` or `ImagePullBackOff` error when Helm tries to pull the default `trainwithshubham/ai-bankapp-eks:latest` image.

Checking the pod events (`kubectl describe pod <pod-name>`) will reveal:
`failed to pull and unpack image... no match for platform in manifest: not found`

**The Fix: Build and Load a Local Image**
Instead of relying on the AMD64 image from Docker Hub, compile it locally for your specific hardware and load it directly into your cluster.

1. **Build the image locally:**
Navigate to the root of the application directory (where the `Dockerfile` is) and build it:
```bash
docker build -t my-local-bankapp:latest .

```


2. **Load the image into your KinD cluster:**
Push the locally built image directly into the cluster's nodes (replace `tws-cluster` with your actual KinD cluster name):
```bash
kind load docker-image my-local-bankapp:latest --name tws-cluster

```


3. **Update your Helm `values.yaml`:**
Tell Helm to use this new local image and to *stop* trying to download it from the internet by setting the `pullPolicy` to `IfNotPresent`:
```yaml
bankapp:
  image:
    repository: my-local-bankapp
    tag: "latest"
    pullPolicy: IfNotPresent

```


4. **Push the fix to the cluster:**
Run a quick Helm upgrade to apply the new values:
```bash
helm upgrade my-bankapp bankapp/ -n bankapp

```

---


## Hints

* `helm template` is your best debugging tool — always render locally before deploying
* `helm lint` catches common issues: missing required fields, YAML syntax errors, template bugs
* Go template whitespace is tricky — use `{{-` to trim leading whitespace and `-}}` to trim trailing
* `b64enc` is a Helm function that base64 encodes strings — no need to manually encode secrets
* `toYaml` converts a YAML object from values into proper YAML in the template — always pair with `nindent`
* `include` calls a helper function and returns a string (pipeable). `template` streams directly (not pipeable)
* The `{{- if }} / {{- end }}` pattern for MySQL and Ollama means the chart works with or without those components
* Reference: https://github.com/TrainWithShubham/AI-BankApp-DevOps (branch: `feat/gitops`) — the `k8s/` directory has the original manifests

---
