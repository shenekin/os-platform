针对Ubuntu 24.04克隆后IP冲突的问题，核心原因是你看到的：**Ubuntu默认使用`/etc/machine-id`（而非MAC地址）作为DHCP请求的唯一标识**。克隆出的虚拟机`machine-id`相同，DHCP服务器会认为它们是一台机器，因此分配了相同的IP。

解决思路很简单，有两个方法，推荐根据你的场景二选一：

### ⭐ 方案一：修改Netplan配置（最简单，推荐）

这个方法让系统直接使用网卡的MAC地址作为DHCP的唯一标识，一劳永逸。

1.  **找到你的Netplan配置文件**：Ubuntu 24.04的网络配置文件通常在`/etc/netplan/`目录下，文件名可能是`50-cloud-init.yaml`或`00-installer-config.yaml`。你可以用`ls /etc/netplan/`查看具体名字。
2.  **编辑文件**：使用`nano`或`vi`编辑该文件，例如：
    ```bash
    sudo nano /etc/netplan/50-cloud-init.yaml
    ```
3.  **添加关键配置**：在对应网卡（如`ens33`）的配置下，添加一行`dhcp-identifier: mac`。确保格式正确（注意缩进和冒号后的空格）。修改后的配置类似这样：
    ```yaml
    network:
      version: 2
      ethernets:
        ens33:      # 你的网卡名称
          dhcp4: true
          dhcp-identifier: mac   # 核心配置，使用MAC地址作为ID
    ```
4.  **应用配置**：保存文件后，运行以下命令使配置生效：
    ```bash
    sudo netplan apply
    ```

### 🛠️ 方案二：重新生成`machine-id`（更彻底）

如果你希望保持系统原有的机制，那就需要为每个克隆单独生成一个唯一的`machine-id`。

1.  **删除旧的ID**：
    ```bash
    sudo rm /etc/machine-id /var/lib/dbus/machine-id
    ```
2.  **生成新的唯一ID**：
    ```bash
    sudo systemd-machine-id-setup
    ```
3.  **重启系统**让新ID和网络服务一起生效：
    ```bash
    sudo reboot now
    ```
    > 如果你想在制作模板时就预处理，可以在关机前执行`sudo cloud-init clean --machine-id`来清理。

### ⚠️ 别忘了检查MAC地址

请确认克隆后的虚拟机**网卡MAC地址已经不同**。如果MAC地址也相同，DHCP服务器会完全混淆。你可以在虚拟机设置里“生成”一个新的MAC地址。