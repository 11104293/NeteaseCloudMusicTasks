if [ -z "$TENCENT_SECRET_ID" ] || [ -z "$TENCENT_SECRET_KEY" ]; then
	echo "请配置SECRET_ID和SECRET_KEY两个secrets";
	echo -e "\033[1;31m 部署失败 \033[0m"
	exit 1
fi
if [ -z "$FUNCTION_NAME" ]; then
	FUNCTION_NAME="NeteaseCloudMusicTasks";
fi
if [ -z "$REGION" ]; then
	REGION="ap-guangzhou";
fi
url=`python ./serverless/geturl.py $TENCENT_SECRET_ID $TENCENT_SECRET_KEY $FUNCTION_NAME $REGION`;
if [[ $url == *ERROR* ]]; then
	# 未部署函数
	if [[ $url == *ResourceNotFound* ]]; then
		echo "函数尚未创建"
	else
		echo $url
		echo -e "\033[1;31m 部署失败 \033[0m"
		exit 1
	fi
else
	echo "正在下载代码文件";
	wget --no-check-certificate -q -O code.zip "$url";
	echo "已下载代码文件";
	sudo apt install -y unzip  >> /dev/null;
	echo "正在解压"
	unzip -o code.zip -d code/  >> /dev/null;
	rm -f code.zip;
	sudo mv ./code/config.json ./oldconfig.json;
	python ./serverless/loadconfig.py;
	echo "已加载配置文件";		
fi

echo "开始安装ServerlessFramework";
sudo npm install -g serverless  >> /dev/null;
sudo mkdir tmp/;
shopt -s extglob;
sudo mv !(tmp|serverless|public|code|.github|.git) ./tmp;
sudo mv ./serverless/serverless.yml ./tmp;

cd ./tmp;
if [ -n "$CRON" ]; then
	sudo sed -i "s/0 30 0 \* \* \* \*/${CRON}/g" ./serverless.yml;
fi
if [ -n "$REGION" ]; then
	sudo sed -i "s/ap-guangzhou/${REGION}/g" ./serverless.yml;
fi
if [ -n "$FUNCTION_NAME" ]; then
	sudo sed -i "s/NeteaseCloudMusicTasks/${FUNCTION_NAME}/g" ./serverless.yml;
fi
echo "开始部署到腾讯云函数";
result=`sls deploy --debug`;
if [[ $result == *执行成功* ]]; then
	echo -e "\033[1;32m 部署成功 \033[0m"
else
	echo $result;
	echo -e "\033[1;31m 部署失败 \033[0m"
	exit 1;
fi

