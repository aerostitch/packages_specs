#!/bin/bash

LOCAL_REPO=/tmp/hg/vim
RPM_SOURCES_DIR=./SOURCES

mkdir -p "$LOCAL_REPO"
# If it is your 1st time, run a clone:
# hg clone https://code.google.com/p/vim/ $LOCAL_REPO

#Updating local repo from central source
pushd $LOCAL_REPO
hg pull
# Retriving last revisionned tag
revision=$(hg tags | head -2 |  perl -ne 'if($_ =~ /v([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[[:space:]].*/){print $1 .".". $2 .".". $3."\n"}')
# create a temp directory without the mercurial references
TMP_REPO=$(mktemp -d)
hg archive ${TMP_REPO}/vim-${revision}
# and create the tarball that will be used by the RPM
popd
pushd ${TMP_REPO}
# Solving issues about not having nawk on AIX
perl -pe 's/#!\/usr\/bin\/nawk/#!\/usr\/bin\/awk/g' -i ${TMP_REPO}/vim-${revision}/runtime/tools/mve.awk
tar -cvf ${RPM_SOURCES_DIR}/vim-${revision}.tar.bz2 --bzip2 vim-${revision}
popd
rm -r ${TMP_REPO}

echo "---------------- TO REGENERATE FILES LIST ----------------"
echo "cd vim-${revision}-root && find . -type f | perl -pe 's/^\.(.*)\$/\1/g' | perl -pe 's/^(.*\/man\/.*)\$/%doc %attr(0444,root,root) \\1/g' >> ./SPECS/vim.spec"
echo "---------------- TO CHANGE BEFORE BUILDING RPM ----------------"
echo "Change, in the SPECS/vim.spec lines: "
echo "%define release           N"
echo "%define version           ${revision}"

echo "---------------- TO BUILD RPM AFTER MODIFYING SPEC FILE  ----------------"
echo "rpm -bb --clean SPECS/vim.spec"
