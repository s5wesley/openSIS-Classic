#!/bin/bash

# Set Helm chart name
CHART_NAME="opensis-chart"

# Step 1: Create Helm Chart Directory
echo "📂 Creating Helm Chart Directory: $CHART_NAME"
mkdir -p $CHART_NAME/templates

# Step 2: Create Chart.yaml
cat <<EOF > $CHART_NAME/Chart.yaml
apiVersion: v2
name: opensis
description: A Helm chart to deploy OpenSIS on Kubernetes
type: application
version: 1.0.0
appVersion: 1.0.0
EOF

# Step 3: Create values.yaml
cat <<EOF > $CHART_NAME/values.yaml
replicaCount: 1

image:
  repository: your-dockerhub-account/opensis
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 8080

db:
  image: mysql:5.7
  rootPassword: rootpassword
  database: opensis
  user: opensisuser
  password: opensispassword
  port: 3306

persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 1Gi
EOF

# Step 4: Create OpenSIS Deployment Template
cat <<EOF > $CHART_NAME/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensis
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: opensis
  template:
    metadata:
      labels:
        app: opensis
    spec:
      containers:
        - name: opensis
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: opensis-config
          volumeMounts:
            - name: opensis-data
              mountPath: /var/www/html
      volumes:
        - name: opensis-data
          persistentVolumeClaim:
            claimName: opensis-pvc
EOF

# Step 5: Create MySQL Deployment Template
cat <<EOF > $CHART_NAME/templates/deployment-db.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensis-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opensis-db
  template:
    metadata:
      labels:
        app: opensis-db
    spec:
      containers:
        - name: mysql
          image: "{{ .Values.db.image }}"
          ports:
            - containerPort: 3306
          envFrom:
            - secretRef:
                name: opensis-db-secret
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-data
          persistentVolumeClaim:
            claimName: mysql-pvc
EOF

# Step 6: Create OpenSIS Service
cat <<EOF > $CHART_NAME/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: opensis
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
  selector:
    app: opensis
EOF

# Step 7: Create MySQL Service
cat <<EOF > $CHART_NAME/templates/service-db.yaml
apiVersion: v1
kind: Service
metadata:
  name: opensis-db
spec:
  type: ClusterIP
  ports:
    - port: {{ .Values.db.port }}
      targetPort: 3306
  selector:
    app: opensis-db
EOF

# Step 8: Create Persistent Volume Claim (PVC)
cat <<EOF > $CHART_NAME/templates/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: opensis-pvc
spec:
  accessModes:
    - {{ .Values.persistence.accessMode }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - {{ .Values.persistence.accessMode }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
EOF

# Step 9: Create Secret for Database Credentials
cat <<EOF > $CHART_NAME/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: opensis-db-secret
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: {{ .Values.db.rootPassword | b64enc }}
  MYSQL_DATABASE: {{ .Values.db.database | b64enc }}
  MYSQL_USER: {{ .Values.db.user | b64enc }}
  MYSQL_PASSWORD: {{ .Values.db.password | b64enc }}
EOF

# Step 10: Create ConfigMap for Database Connection
cat <<EOF > $CHART_NAME/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opensis-config
data:
  DATABASE_HOST: "opensis-db"
  DATABASE_PORT: "{{ .Values.db.port }}"
  DATABASE_NAME: "{{ .Values.db.database }}"
  DATABASE_USER: "{{ .Values.db.user }}"
EOF

echo "✅ Helm Chart for OpenSIS created successfully in ./$CHART_NAME"
echo "🚀 Next steps:"
echo "1. Change to the chart directory: cd $CHART_NAME"
echo "2. Verify the chart: helm lint ."
echo "3. Package the chart: helm package ."
echo "4. Deploy it using: helm install opensis ./opensis-chart"
echo "To uninstall: helm uninstall opensis"

