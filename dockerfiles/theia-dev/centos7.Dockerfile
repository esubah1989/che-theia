# Copyright (c) 2018-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM centos:7

RUN \
    # Add yum repository for nodejs 10.x
    curl -sL https://rpm.nodesource.com/setup_10.x | bash - && \
    yum install -y nodejs && \
    # Add EPEL repository (jq)
    yum install -y epel-release && \
    yum install -y \
    # To play with json in shell
    jq \
    # compile some javascript native stuff (node-gyp)
    make gcc gcc-c++ python \
    # clone repositories
    git \
    # Handle git diff properly
    less \
    # some lib to compile 'native-keymap' npm mpdule
    libX11-devel libxkbfile-devel && \
    yum clean all && \
    # Install yarn
    npm install -g yarn

# Add npm global bin directory to the path
ENV HOME=/home/theia-dev \
    PATH=/home/theia-dev/.npm-global/bin:${PATH} \
    # Specify the directory of git (avoid to search at init of Theia)
    USE_LOCAL_GIT=true \
    LOCAL_GIT_DIRECTORY=/usr \
    GIT_EXEC_PATH=/usr/libexec/git-core \
    THEIA_ELECTRON_SKIP_REPLACE_FFMPEG=true

# Define package of the theia generator to use
ARG THEIA_GENERATOR_PACKAGE=@eclipse-che/theia-generator@0.0.1-1559634039

WORKDIR ${HOME}

# Exposing Theia ports
EXPOSE 3000 3030

# Configure npm and yarn to use home folder for global dependencies
RUN npm config set prefix "${HOME}/.npm-global" && \
    echo "--global-folder \"${HOME}/.yarn-global\"" > ${HOME}/.yarnrc && \
    # add eclipse che theia generator
    yarn global add yo @theia/generator-plugin@0.0.1-1540209403 ${THEIA_GENERATOR_PACKAGE} && \
    # Generate .passwd.template \
    cat /etc/passwd | \
    sed s#root:x.*#theia-dev:x:\${USER_ID}:\${GROUP_ID}::${HOME}:/bin/bash#g \
    > ${HOME}/.passwd.template && \
    # Generate .group.template \
    cat /etc/group | \
    sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
    > ${HOME}/.group.template && \
    mkdir /projects && \
    # Define default prompt
    echo "export PS1='\[\033[01;33m\](\u@container)\[\033[01;36m\] (\w) \$ \[\033[00m\]'" > ${HOME}/.bashrc  && \
    # Disable the statistics for yeoman
    mkdir -p ${HOME}/.config/insight-nodejs/ && \
    echo '{"optOut": true}' > ${HOME}/.config/insight-nodejs/insight-yo.json && \
    # Change permissions to let any arbitrary user
    for f in "${HOME}" "/etc/passwd" "/etc/group" "/projects"; do \
        echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && \
        chmod -R g+rwX ${f}; \
    done

WORKDIR "/projects"

ADD src/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD tail -f /dev/null
