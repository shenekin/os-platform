#!/bin/bash

RESOURCE_GROUP="rg-aks-dev"
AKS_CLUSTER="aks-dev"
ACR_NAME="ekinregistry"
SERVICE_PRINCIPAL_NAME="jenkins-aks-sp"

echo "Creating service principal..."
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name $SERVICE_PRINCIPAL_NAME \
    --role Contributor \
    --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP)

APP_ID=$(echo $SP_OUTPUT | jq -r '.appId')
PASSWORD=$(echo $SP_OUTPUT | jq -r '.password')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenant')

echo "Service Principal created:"
echo "App ID: $APP_ID"
echo "Tenant ID: $TENANT_ID"
echo "Password: $PASSWORD"

echo "Assigning ACR permissions..."
ACR_ID=$(az acr show \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --query id \
    --output tsv)

az role assignment create \
    --assignee $APP_ID \
    --role Contributor \
    --scope $ACR_ID

echo "Assigning AKS permissions..."
AKS_ID=$(az aks show \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER \
    --query id \
    --output tsv)

az role assignment create \
    --assignee $APP_ID \
    --role "Azure Kubernetes Service Cluster Admin Role" \
    --scope $AKS_ID

echo "Permission assignment completed successfully!"
