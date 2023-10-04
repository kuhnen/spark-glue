#!/bin/bash
#set -ex
set -e
HADOOP_VERSION=3.3.0
HADOOP_FILE_NAME=hadoop-${HADOOP_VERSION}.tar.gz
SPARK_FILE_NAME=spark-3.4.1-bin-hadoop-provided-glue.tgz

if [ -f "$SPARK_FILE_NAME" ]; then
  echo "$SPARK_FILE_NAME already exists"
else
  docker build -t spark3-glue .
  docker create -it --name dummy spark3-glue bash
  docker cp dummy:/opt/spark_clone/${SPARK_FILE_NAME} .
  docker rm -fv dummy
fi

if [ -f "$HADOOP_FILE_NAME" ]; then
  echo "$HADOOP_FILE_NAME already exists."
else
  wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
fi

#example
echo "Unfortunately you need to use java 1.8 to make it work"
echo "If you wish to run the spark-shell locally and with access to aws data catalog you need to run the following commands: "

echo "tar -xzvf $HADOOP_FILE_NAME"
echo ""
echo "export HADOOP_HOME=${PWD}/hadoop-${HADOOP_VERSION}"
export HADOOP_HOME=${PWD}/hadoop-${HADOOP_VERSION}
echo "export SPARK_DIST_CLASSPATH=$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
#echo "export SPARK_DIST_CLASSPATH={$HADOOP_HOME}/etc/hadoop/*:HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
echo ""
echo "tar -xzvf $SPARK_FILE_NAME"

#TAR_SUFFIX=.tgz
#echo "cd ${SPARK_FILE_NAME%"$TAR_SUFFIX"}"
echo "cd dist/"
echo "./bin/spark-sql"
echo "Enjoy it. Order some beer and and relax"
