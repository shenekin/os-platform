import time
from nacos import NacosClient

# -------------------------- Your Nacos Configuration --------------------------
# Core Nacos server address (matches your NACOS_SERVER_ADDRESSES)
NACOS_SERVER_ADDRESSES = "localhost:8848"
# Namespace (matches your NACOS_NAMESPACE)
NACOS_NAMESPACE = "public"
# Group (matches your NACOS_GROUP)
NACOS_GROUP = "DEFAULT_GROUP"
# Service name (matches your NACOS_SERVICE_NAME)
NACOS_SERVICE_NAME = "project-service"
# Service port (matches your NACOS_SERVICE_PORT)
NACOS_SERVICE_PORT = 8002
# Service IP (matches your NACOS_SERVICE_IP)
NACOS_SERVICE_IP = "localhost"

# Optional: Add these if your Nacos server has authentication enabled (default: nacos/nacos)
NACOS_USERNAME = "nacos"
NACOS_PASSWORD = "nacos"

def register_service_to_nacos():
    """
    Register service to Nacos and maintain heartbeat (critical for health check)
    """
    try:
        # 1. Initialize Nacos client
        client = NacosClient(
            server_addresses=NACOS_SERVER_ADDRESSES,
            namespace=NACOS_NAMESPACE,
            username=NACOS_USERNAME,
            password=NACOS_PASSWORD
        )

        # 2. Register service instance to Nacos (移除了无效的beat_interval参数)
        register_success = client.add_naming_instance(
            service_name=NACOS_SERVICE_NAME,
            ip=NACOS_SERVICE_IP,
            port=NACOS_SERVICE_PORT,
            group_name=NACOS_GROUP,
            # Optional: Add metadata (e.g., version, weight) for the service
            metadata={"version": "1.0", "weight": 1.0}
        )

        if register_success:
            print(f"✅ Service '{NACOS_SERVICE_NAME}' registered to Nacos successfully!")
            print(f"🔍 Registration Info: IP={NACOS_SERVICE_IP}, Port={NACOS_SERVICE_PORT}, Group={NACOS_GROUP}")
        else:
            print("❌ Failed to register service! Check Nacos connection and configuration.")
            return

        # 3. Maintain heartbeat (Nacos will mark the instance as unhealthy without heartbeat)
        print("\n📌 Keeping service heartbeat alive (press Ctrl+C to stop)...")
        while True:
            # Send heartbeat actively (SDK also sends auto-heartbeat, manual send is more reliable)
            client.send_heartbeat(
                service_name=NACOS_SERVICE_NAME,
                ip=NACOS_SERVICE_IP,
                port=NACOS_SERVICE_PORT,
                group_name=NACOS_GROUP
            )
            time.sleep(5)  # Send heartbeat every 5 seconds

    except Exception as e:
        print(f"❌ Error during registration: {str(e)}")
        raise

if __name__ == "__main__":
    # Run the registration function
    register_service_to_nacos()

