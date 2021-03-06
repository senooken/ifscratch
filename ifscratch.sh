:
################################################################################
## \file      ifscratch.sh
## \author    SENOO, Ken
## \copyright CC0
## \version   0.2.0
################################################################################

: <<-"EOT"
引数にパッケージ名、バージョン名、タグ名順番に受け取り指定したパッケージをインストールする。
例:
ifscratch.sh zlib 1.2.12 v1.2.12
EOT

EXE_NAME='ifscratch'
ifscratch() {
	STOW=stow
	LOCAL=$([ $(id -u) = 0 ] && echo /usr/ || echo ~/.)local
	J=$(grep -cs '^processor' /proc/cpuinfo || echo 2)
	TAB=$(printf '\t.') TAB=${TAB%.}
	SEP=$TAB,
	ifscratch_arg ${1+"$@"}
	ifscratch_body
}

## \brief 処理に必要な情報をファイルから取得する。
ifscratch_arg() {
	PKG=$1 VER=${2-} TAG=${3-}
	LINE=$(grep "^$PKG[$SEP].*" $EXE_NAME.csv)
	IFS=$SEP
	set -- $LINE
	unset IFS
	URL=$2 MANDATORY=${3-} TAGS=${4-} SRC=${5-}

	[ "${MANDATORY##*|*}" ] && return;
	set -- $MANDATORY
	while [ -n "${1-}" ]; do
		## Skip if package installed.
		[ -e "$LOCAL/stow/$1"* ] && continue
		($EXE_NAME "$1")
		shift
	done
}

ifscratch_body() {
	mkdir -p "$LOCAL/src"
	cd "$LOCAL/src"

	if command -v git >/dev/null; then
		[ -e $PKG ] || git clone --depth 1 $URL $PKG
		cd $PKG
		if [ -z "${TAG-}" ]; then
			TAG=$(git ls-remote -t --sort=-version:refname origin ${TAGS-} | head -n 1 | sed 's@.*/@@; s@\^{}$@@')
			if git ls-remote -t --sort=-creatordate >/dev/null 2>&1; then
				TAG=$(git ls-remote -t --sort=-creatordate origin ${TAGS-} | head -n 1 | sed 's@.*/@@')
			fi
			## \todo specify version only
			if ! [ ${VER-} ]; then
				# TAG: PKG-VER, PKG-vVER, 0_0_1
				VER=$(printf '%s\n' "$TAG" | sed 's/^[^0-9]*//; s/[_-]/./g; s/[^0-9.]//g')
			fi
		fi
		PKG_VER=$PKG${VER:+-$VER}
		if [ -e "$LOCAL/stow/$PKG_VER" ]; then
			return
		fi
		git fetch --depth 1 origin tag $TAG
		git checkout -f $TAG
		git clean -dfX
		if [ -e .gitmodules ]; then
			git submodule update --init --depth 1
			git submodule foreach git clean -dfX
		fi
		## change another source directory
		[ -n ${SRC-} ] && cd $SRC
		# [ -e .gitmodules ] && git submodule foreach --recursive git clean -dfX
		# [ -e configure.ac ] && autoreconf -is
		# ./buildconf
	else
		:
		# [ -e $PKG-$VER ] || wget http://archive.apache.org/dist/apr/$PKG-$VER.tar.bz2
		# tar -xf $PKG-$VER.*
		# cd $PKG-$VER
	fi
	make -kj $J distclean clean || :
	[ -e configure ] || ([ -e configure.ac ] && autoreconf -fis)
	[ -x configure ] && ./configure --prefix="$LOCAL/stow/$PKG_VER"
	make -j $J
	# make -j $J check
	make -j $J install

	cd "$LOCAL/stow"
	echo $PKG${VER:+-}[0-9]* | xargs -n 1 $STOW -D
	$STOW $PKG_VER
}


main() {
	## \brief Initialize POSIX shell environment
	init() {
		PATH="$(command -p getconf PATH 2>&-):${PATH:-.}"
		export PATH="${PATH#:}" LC_ALL='C'
		umask 0022
		set -eu
	}

	is_main() { [ "$EXE_NAME.sh" = "${0##*/}" ]; }
	if is_main; then
		init
		$EXE_NAME ${1+"$@"}
	fi
}

main ${1+"$@"}

