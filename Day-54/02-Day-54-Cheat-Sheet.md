# 🛡️ Day 54 Cheat Sheet: ConfigMaps & Secrets

## 📄 1. ConfigMaps (Non-Sensitive)

**Create from Command Line (Literals):**
```bash
kubectl create configmap app-settings \
  --from-literal=ENV=prod \
  --from-literal=PORT=8080

```

**Create from a File:**

```bash
# The file name automatically becomes the key
kubectl create configmap nginx-config --from-file=default.conf

```

**Inspect a ConfigMap:**

```bash
kubectl get configmap app-settings -o yaml

```

## 🔐 2. Secrets (Sensitive)

**Create from Command Line:**

```bash
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password=supersecret

```

**Decode a Secret Value Safely:**

```bash
# Extracts the exact value and decodes it without a trailing newline
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 --decode

```

**Encode a Value Manually:**

```bash
# The -n flag prevents encoding the invisible "enter" key stroke
echo -n 'supersecret' | base64

```

## ⚙️ 3. Pod Injection Syntax

**Injecting all keys as Environment Variables (`envFrom`):**

```yaml
    envFrom:
    - configMapRef:
        name: app-settings
    - secretRef:
        name: db-creds

```

**Mounting as a File Volume:**

```yaml
    volumeMounts:
    - name: config-vol
      mountPath: /etc/nginx/conf.d
  volumes:
  - name: config-vol
    configMap:
      name: nginx-config

```

## 🚨 SRE Troubleshooting Quick Fixes

* **Pod stuck in `ContainerCreating`?**
You misspelled the `name` of the ConfigMap in your volume definition, or it doesn't exist yet. The kubelet will hang infinitely waiting for it.
* **Pod crashing with `strict decoding error`?**
YAML indentation issue. Check your `configMapRef` spacing.
* **My application isn't seeing the new ConfigMap value!**
If it was injected via an environment variable, you *must* restart the Pod (`kubectl delete pod <name>`). If it was a volume mount, wait up to 60-120 seconds for the `kubelet` sync loop to update the symlinks.

---
