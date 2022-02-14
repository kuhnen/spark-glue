ARG java_image_tag=8-jre-slim
FROM python:3.10.2-slim-buster
#FROM ubuntu:18.04
FROM openjdk:8


# Build options
ARG hive_version=2.3.7
ARG spark_version=3.1.2
ARG hadoop_version=3.3.0

ENV SPARK_VERSION=${spark_version}
ENV HIVE_VERSION=${hive_version}
ENV HADOOP_VERSION=${hadoop_version}

WORKDIR /

RUN apt-get update
RUN apt-get install -y patch wget python3-setuptools
#RUN apt-get install -y wget
#RUN apt-get install -y python3-setuptools
# JDK repo
#RUN echo "deb http://ftp.us.debian.org/debian sid main" >> /etc/apt/sources.list \
#  &&  apt-get update \
#  &&  mkdir -p /usr/share/man/man1


#RUN apt-get install -y git curl wget openjdk-8-jdk patch && rm -rf /var/cache/apt/*

# maven
ENV MAVEN_VERSION=3.6.3
ENV PATH=/opt/apache-maven-$MAVEN_VERSION/bin:$PATH
ENV MAVEN_HOME /opt/apache-maven-${MAVEN_VERSION}

RUN cd /opt \
  &&  wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  &&  tar zxvf /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  &&  rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

COPY ./maven-settings.xml ${MAVEN_HOME}/conf/settings.xml

WORKDIR /opt
#BUILD HIVE
ADD https://github.com/apache/hive/archive/rel/release-${hive_version}.tar.gz hive.tar.gz
RUN mkdir hive && tar xzf hive.tar.gz --strip-components=1 -C hive
WORKDIR /opt/hive
ADD https://issues.apache.org/jira/secure/attachment/12958418/HIVE-12679.branch-2.3.patch hive.patch
#### Build patched hive
RUN patch -p0 <hive.patch &&\
  mvn  clean install -DskipTests

## Glue support
WORKDIR /opt
RUN git clone https://github.com/bbenzikry/aws-glue-data-catalog-client-for-apache-hive-metastore catalog
## Glue support

### Build glue hive client jars
WORKDIR /opt/catalog
RUN mvn clean package -DskipTests -pl -aws-glue-datacatalog-hive2-client
### Build glue hive client jars

#install hadoop
WORKDIR /opt/hadoop
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz
ARG HADOOP_WITH_VERSION=hadoop-${HADOOP_VERSION}
#RUN mv -v hadoop-${HADOOP_VERSION}/* .
ENV SPARK_DIST_CLASSPATH=$HADOOP_HOME/$HADOOP_WITH_VERSION/etc/hadoop/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/common/lib/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/common/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/hdfs/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/hdfs/lib/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/hdfs/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/yarn/lib/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/yarn/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/mapreduce/*:$HADOOP_HOME/$HADOOP_WITH_VERSION/share/hadoop/tools/lib/*
#install hadoop

#BUILD SPARK
WORKDIR /opt
RUN git clone https://github.com/apache/spark.git spark_clone
##cd spark_clone
WORKDIR /opt/spark_clone

RUN git checkout "tags/v${SPARK_VERSION}" -b "v${SPARK_VERSION}"
#RUN ./dev/make-distribution.sh --name spark-patched --pip -Pkubernetes -Phive -Phive-thriftserver -Phadoop-provided -Dhadoop.version="${HADOOP_VERSION}"
RUN ./dev/make-distribution.sh --name spark-patched --pip -Phive -Phive-thriftserver -Phadoop-provided -Dhadoop.version="${HADOOP_VERSION}"

COPY conf/* ./dist/conf
RUN find /opt/catalog -name "*.jar" | grep -Ev "test|original" | xargs -I{} cp {} ./dist/jars
ENV DIRNAME=spark-${SPARK_VERSION}-bin-hadoop-provided-glue
#BUILD SPARK


RUN echo "Uploading to DIRNAME $DIRNAME"
RUN echo $SPARK_DIST_CLASSPATH

WORKDIR /opt/spark_clone

ARG DIRNAME=spark-${SPARK_VERSION}-bin-hadoop-provided-glue
#RUN echo "Uploading to DIRNAME $DIRNAME"
#RUN mv /mnt/ramdisk/spark_clone/dist "/$DIRNAME"
#cd /
RUN echo "Creating archive $DIRNAME.tgz"
RUN tar -cvzf "$DIRNAME.tgz" dist
