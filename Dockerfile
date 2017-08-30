FROM repo.splunk.com/ucp_healthcheck:1


RUN apt-get update
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y python
RUN apt-get install -y vim
RUN apt-get install -y wget
RUN apt-get install -y net-tools
RUN apt-get install -y telnet
RUN apt-get install -y sendmail


ARG user=monitor
ARG group=monitor
ARG uid=510
ARG gid=510

#RUN addgroup -g ${gid} ${group} \
# && adduser -D -u ${uid} -G ${group} ${user}

#USER ${user}
ENV HOME /home/

RUN apt-get update

COPY . $HOME/repo
#ADD . $HOME/repo



RUN cd $HOME/repo
#RUN cd $HOME/repo && bash health_check.sh

WORKDIR $HOME/repo
#RUN bash health_check.sh
# WORKDIR $GOPATH/bin/
# RUN avanti-server --port=41491 --host 0.0.0.0 &

RUN python -m SimpleHTTPServer 2223 &

EXPOSE 2223 2224 2225 2226

#RUN PATH="$HOME/repo/health_check.sh:$PATH"
#ENTRYPOINT ["$HOME/repo/health_check.sh"]
CMD bash $HOME/repo/health_check.sh
