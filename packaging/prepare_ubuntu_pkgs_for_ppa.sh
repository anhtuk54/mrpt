#!/bin/bash
# Creates a set of packages for each different Ubuntu distribution, with the
# intention of uploading them to:
#   https://launchpad.net/~joseluisblancoc/+archive/mrpt
#
# You can declare a variable (in the caller shell) with extra flags for the
# CMake in the final ./configure like:
#  MRPT_PKG_CUSTOM_CMAKE_PARAMS="\"-DENABLE_SSE3=OFF\""
#
# TODO: Update script to work with gdb!

set -e

# List of distributions to create PPA packages for:
#  - Hirsute    EOL: Jan 2022
#  - Bionic LTS EOL: Apr 2023
#  - Focal  LTS EOL: Apr 2025
#  - Impish     EOL: Jul 2022
if [ -z ${LST_DISTROS+x} ]; then
	LST_DISTROS=(bionic focal hirsute impish)
fi

count=${#LST_DISTROS[@]}
echo "========================================================================="
echo " Ubuntu PPA script for $count distros: ${LST_DISTROS[@]}"
echo "========================================================================="

# Special case for Bionic: use embedded version of simpleini
# (Remove these lines after xenial and bionic EOL)
export MRPT_PKG_EXPORTED_SUBMODULES_bionic="simpleini nanoflann"
export DEB_EXTRA_BUILD_DEPS_bionic="cmake"  # dummy package (it cannot be blank)
export DEB_NANOFLANN_DEP_bionic="libmrpt-common-dev"  # dummy package (it cannot be blank)

export MRPT_PKG_EXPORTED_SUBMODULES_focal="nanoflann"
export DEB_EXTRA_BUILD_DEPS_focal="libsimpleini-dev"
export DEB_NANOFLANN_DEP_focal="libmrpt-common-dev"  # dummy package (it cannot be blank)

export MRPT_PKG_EXPORTED_SUBMODULES_hirsute=""
export DEB_EXTRA_BUILD_DEPS_hirsute="libsimpleini-dev, libnanoflann-dev"
export DEB_NANOFLANN_DEP_hirsute="libnanoflann-dev"  # make mrpt-math-dev to depend on nanoflann headers

export MRPT_PKG_EXPORTED_SUBMODULES_impish=""
export DEB_EXTRA_BUILD_DEPS_impish="libsimpleini-dev, libnanoflann-dev"
export DEB_NANOFLANN_DEP_impish="libnanoflann-dev"  # make mrpt-math-dev to depend on nanoflann headers


# Checks
# --------------------------------
if [ -f version_prefix.txt ];
then
	MRPT_VERSION_STR=`head -n 1 version_prefix.txt`
	MRPT_VERSION_MAJOR=${MRPT_VERSION_STR:0:1}
	MRPT_VERSION_MINOR=${MRPT_VERSION_STR:2:1}
	MRPT_VERSION_PATCH=${MRPT_VERSION_STR:4:1}

	MRPT_VER_MM="${MRPT_VERSION_MAJOR}.${MRPT_VERSION_MINOR}"
	MRPT_VER_MMP="${MRPT_VERSION_MAJOR}.${MRPT_VERSION_MINOR}.${MRPT_VERSION_PATCH}"
	echo "MRPT version: ${MRPT_VER_MMP}"
else
	echo "ERROR: Run this script from the MRPT root directory."
	exit 1
fi

if [ -z "${MRPT_UBUNTU_OUT_DIR}" ]; then
       export MRPT_UBUNTU_OUT_DIR="$HOME/mrpt_ubuntu"
fi
MRPTSRC=`pwd`
if [ -z "${MRPT_DEB_DIR}" ]; then
       export MRPT_DEB_DIR="$HOME/mrpt_debian"
fi
MRPT_EXTERN_DEBIAN_DIR="$MRPTSRC/packaging/debian/"
EMAIL4DEB="Jose Luis Blanco (University of Malaga) <joseluisblancoc@gmail.com>"

# Clean out dirs:
rm -fr $MRPT_UBUNTU_OUT_DIR/

# -------------------------------------------------------------------
# And now create the custom packages for each Ubuntu distribution:
# -------------------------------------------------------------------
# Xenial:armhf does not have any version of liboctomap-dev:
#export MRPT_RELEASE_EXTRA_OTHERLIBS_URL="https://github.com/OctoMap/octomap/archive/v1.9.1.zip"
#export MRPT_RELEASE_EXTRA_OTHERLIBS_PATH="3rdparty/octomap.zip"

IDXS=$(seq 0 $(expr $count - 1))

cp ${MRPT_EXTERN_DEBIAN_DIR}/changelog /tmp/my_changelog

for IDX in ${IDXS};
do
	DEBIAN_DIST=${LST_DISTROS[$IDX]}

	# -------------------------------------------------------------------
	# Call the standard "prepare_debian.sh" script:
	# -------------------------------------------------------------------
	cd ${MRPTSRC}
	auxVarName=MRPT_PKG_CUSTOM_CMAKE_PARAMS_${DEBIAN_DIST}
	auxVarName=${!auxVarName} # Replace by variable contents

	auxVarName2=MRPT_PKG_EXPORTED_SUBMODULES_${DEBIAN_DIST}
	export MRPT_PKG_EXPORTED_SUBMODULES=${!auxVarName2} # Replace by variable contents

	auxVarName2=DEB_EXTRA_BUILD_DEPS_${DEBIAN_DIST}
	export DEB_EXTRA_BUILD_DEPS=${!auxVarName2} # Replace by variable contents

	auxVarName2=DEB_NANOFLANN_DEP_${DEBIAN_DIST}
	export DEB_NANOFLANN_DEP=${!auxVarName2} # Replace by variable contents

	bash packaging/prepare_debian.sh -s -u -h -d ${DEBIAN_DIST} ${EMBED_EIGEN_FLAG}  -c "${MRPT_PKG_CUSTOM_CMAKE_PARAMS}${auxVarName}"

	CUR_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	source $CUR_SCRIPT_DIR/generate_snapshot_version.sh # populate MRPT_SNAPSHOT_VERSION

	echo "===== Distribution: ${DEBIAN_DIST}  ========="
	cd ${MRPT_DEB_DIR}/mrpt-${MRPT_VER_MMP}~snapshot${MRPT_SNAPSHOT_VERSION}${DEBIAN_DIST}/debian
	#cp ${MRPT_EXTERN_DEBIAN_DIR}/changelog changelog
	cp /tmp/my_changelog changelog
	DEBCHANGE_CMD="--newversion 1:${MRPT_VERSION_STR}~snapshot${MRPT_SNAPSHOT_VERSION}${DEBIAN_DIST}-1"
	echo "Changing to a new Debian version: ${DEBCHANGE_CMD}"
	echo "Adding a new entry to debian/changelog for distribution ${DEBIAN_DIST}"
	DEBEMAIL=${EMAIL4DEB} debchange $DEBCHANGE_CMD -b --distribution ${DEBIAN_DIST} --force-distribution New version of upstream sources.

	cp changelog /tmp/my_changelog

	echo "Now, let's build the source Deb package with 'debuild -S -sa':"
	cd ..
	# -S: source package
	# -sa: force inclusion of sources
	# -d: don't check dependencies in this system
	debuild -S -sa -d

	# Make a copy of all these packages:
	cd ..
	mkdir -p $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST
	cp mrpt_* $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST/
	echo ">>>>>> Saving packages to: $MRPT_UBUNTU_OUT_DIR/$DEBIAN_DIST/"
done


exit 0
