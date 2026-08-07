# 1. 创建文件并确保脚本在正确的位置
# 将上面的脚本内容保存为 network_setup.sh
# 将配置文件保存为 network_config.conf

# 2. 设置正确的文件权限
chmod +x network_setup.sh

# 3. 确保两个文件在同一目录
ls -la network_setup.sh network_config.conf

# 4. 检查脚本格式（如果从Windows复制，可能需要转换换行符）
dos2unix network_setup.sh network_config.conf
# 如果没有dos2unix，安装它
# sudo apt-get install dos2unix

# 5. 运行脚本
sudo ./network_setup.sh

# Only execuit them
apt-get install dos2unix
dos2unix network_setup.sh network_config.conf
chmod +x network_setup.sh
sudo ./network_setup.sh