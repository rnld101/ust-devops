# Kubernetes RBAC Hands-on Guide

## 📌 Overview

This guide demonstrates how Kubernetes **Role-Based Access Control (RBAC)** works by:

* Creating users with certificates
* Assigning roles and permissions
* Restricting and granting access across namespaces
* Using Service Accounts inside pods

---

## 🔐 1. Create Users and Certificates

Kubernetes does not manage users directly. Instead, it relies on **client certificates** for authentication.

### Step 1.1: Generate Private Keys

```bash
openssl genrsa -out user1.key 2048
openssl genrsa -out user2.key 2048
```

👉 Generates private keys for both users. These keys are used to prove identity.

---

### Step 1.2: Generate CSR (Certificate Signing Request)

```bash
openssl req -new -key user1.key -out user1.csr -subj "/CN=user1/O=dev"
openssl req -new -key user2.key -out user2.csr -subj "/CN=user2/O=QA"
```

👉 Explanation:

* **CN (Common Name)** → Username (`user1`, `user2`)
* **O (Organization)** → Group (`dev`, `QA`)

Kubernetes uses these fields for **RBAC authorization**.

---

### Step 1.3: Verify Files

```bash
ls | grep user
```

👉 Ensures keys and CSR files are created.

---

### Step 1.4: Sign CSR using Kubernetes CA

```bash
openssl x509 -req -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -days 730 -in user1.csr -out user1.crt
openssl x509 -req -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -days 730 -in user2.csr -out user2.crt
```

👉 This step:

* Signs the CSR using the cluster’s **Certificate Authority**
* Produces valid certificates trusted by Kubernetes API server

---

### Step 1.5: Add Credentials to kubeconfig

```bash
kubectl config set-credentials user1 --client-certificate=user1.crt --client-key=user1.key
kubectl config set-credentials user2 --client-certificate=user2.crt --client-key=user2.key
```

👉 Stores authentication details in kubeconfig.

---

### Step 1.6: Verify Users

```bash
cat ~/.kube/config
```

👉 Confirm both users exist.

---

## 📂 2. Create Namespace

```bash
kubectl create ns rbac
```

👉 Namespaces isolate resources. RBAC rules can be scoped per namespace.

---

## 🔄 3. Create Contexts

Contexts connect:

* Cluster
* User
* Namespace

```bash
kubectl config set-context user1-context --cluster=kubernetes --user=user1 --namespace=rbac
kubectl config set-context user2-context --cluster=kubernetes --user=user2 --namespace=rbac
```

### Verify:

```bash
kubectl config get-contexts
```

👉 `*` indicates current context.

---

## 🚫 4. Test Access (Before RBAC)

```bash
kubectl config use-context user1-context
kubectl get pods
```

👉 Output: **Permission Denied**

✔️ This proves:

* Authentication works
* Authorization (RBAC) is not yet configured

---

## 🛠️ 5. Create Roles and Bindings

Switch back to admin:

```bash
kubectl config use-context kubernetes-admin@kubernetes
```

Apply RBAC configs:

```bash
kubectl apply -f dev_role.yaml
kubectl apply -f dev_rolebinding.yaml
kubectl apply -f QA_role.yaml
kubectl apply -f QA_rolebinding.yaml
```

### Verify:

```bash
kubectl get roles -n rbac
kubectl get rolebindings -n rbac
```

👉 Explanation:

* **Role** → Defines permissions (verbs like get, list, create)
* **RoleBinding** → Assigns role to users/groups

---

## 🚀 6. Create Pod as user1

```bash
kubectl config use-context user1-context
kubectl run mypod --image=nginx
```

👉 Works because:

* `dev_role` likely allows pod creation

---

## 👀 7. Access Pod as user2

```bash
kubectl config use-context user2-context
kubectl get pods
```

👉 Works only if QA role allows read access.

---

## 🌍 8. Create Pod in Another Namespace

```bash
kubectl config use-context kubernetes-admin@kubernetes
kubectl create ns demo
kubectl run mypod2 --image=nginx -n demo
```

👉 This pod exists outside `rbac` namespace.

---

## 🚫 9. Test Access Restriction

```bash
kubectl config use-context user2-context
kubectl get pods -n demo
```

👉 Output: **Permission Denied**

✔️ Reason:

* Roles are namespace-specific
* No access granted for `demo`

Check with:

```bash
kubectl auth can-i list pods --as=user2 -n demo
```

---

## 🌐 10. Grant Cluster-Wide Access

```bash
kubectl config use-context kubernetes-admin@kubernetes
kubectl apply -f QA_cluster_role.yaml
kubectl apply -f QA_cluster_binding.yaml
```

👉 Explanation:

* **ClusterRole** → Works across all namespaces
* **ClusterRoleBinding** → Grants cluster-wide permissions

---

## ✅ 11. Verify Access Again

```bash
kubectl config use-context user2-context
kubectl get pods -n demo
```

👉 Now access should be granted.

---

## 🤖 12. Service Account Test

```bash
kubectl config use-context kubernetes-admin@kubernetes
kubectl apply -f sapod.yaml
kubectl exec -it sapod -n rbac -- sh
kubectl get pods
```

👉 Output: **Permission Denied**

✔️ Reason:

* Pods use **default service account**
* No permissions assigned

---

## 🔧 13. Create Custom Service Account

```bash
kubectl create sa mysa
kubectl get sa
```

---

## 🔁 14. Attach Service Account to Pod

Update `sapod.yaml`:

```yaml
spec:
  serviceAccountName: mysa
```

Recreate pod:

```bash
kubectl delete pod sapod -n rbac
kubectl apply -f sapod.yaml
```

---

## 🔗 15. Bind Role to Service Account

Update `QA_rolebinding.yaml`:

```yaml
subjects:
- kind: ServiceAccount
  name: mysa
```

Apply:

```bash
kubectl apply -f QA_rolebinding.yaml
```

👉 Now the service account inherits permissions.

---

## 🔍 16. Verify Inside Pod

```bash
kubectl exec -it sapod -- sh
kubectl get pods
```

👉 Now it works 🎉

✔️ Because:

* Pod uses `mysa`
* `mysa` is bound to a role

---

## 🧠 Key Takeaways

* Kubernetes uses **certificates for authentication**
* RBAC controls **authorization**
* Roles are **namespace-scoped**
* ClusterRoles are **global**
* Service Accounts are used by **pods**
* RoleBindings connect **users → permissions**

---

## 📊 RBAC Flow Summary

```
User/ServiceAccount → Role/ClusterRole → RoleBinding/ClusterRoleBinding → Permissions
```

---

## 🎯 Final Thought

This exercise shows how Kubernetes enforces **least privilege access**, ensuring users and workloads only access what they are allowed to.

---
