{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  libXrandr,
  libXcursor,
  libXfixes,
  libGL,
  libXext,
  systemdLibs,
  openal,
  libvorbis,
  flac,
  cpm-cmake,
  # zlib,
  libsodium,
  freetype
}:
let
  luajit = {
    src = fetchFromGitHub {
      owner = "vittorioromeo";
      repo = "LuaJIT";
      rev = "4dc5ffbf60b16e54274c470fcc022165685c96fe";
      hash = "sha256-oNJbMGpcivoJbm8YvMcBnuLrKhvV0C0ZUOapcoJExLc=";
    };
  };
  SFML = {
    src = fetchFromGitHub {
      owner = "vittorioromeo";
      repo = "SFML";
      rev = "dacceddbd1adee49c7bfd120266e200800550394";
      hash = "sha256-6MIn+C29waqRZPQs0DDSCIN20GBW8ZXToNXcNNMr1H8=";
    };
  };
  zlib = {
    src = fetchFromGitHub {
      owner = "madler";
      repo = "zlib";
      rev = "5a82f71ed1dfc0bec044d9702463dbdf84ea3b71";
      hash = "sha256-L/gubPuMLJ1nq+AVZdwhcv6mkgBYzKJ6ncoYM93LvJ0=";
    };
  };
  imgui = {
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "04316bd223f98e4c40bd82dc5f2a35c4891e4e5f";
      hash = "sha256-CalF5RlZxSmZviosc86i+pJkOVFJKIYmM/lQqIPEZyc=";
    };
  };
  imgui-sfml = {
    src = fetchFromGitHub {
      owner = "vittorioromeo";
      repo = "imgui-sfml";
      rev = "f35f353376281c0a891a4d614a241914ddfcbe29";
      hash = "sha256-NgAEcQsjed6nHRh/uNj2u9gxI7HQDW6G9TUUPpdgP/w=";
    };
  };
  libsodium-cmake = {
    src = fetchFromGitHub {
      owner = "vittorioromeo";
      repo = "libsodium-cmake";
      rev = "fd76500b60fcaa341b6fad24cda88c3504df770d";
      fetchSubmodules = true;
      hash = "sha256-knoRCiE9jKrnr6/9UTftdm0jXRg93z9EJknFDV95kVA=";
    };
  };
  boostpfr = {
    src = fetchFromGitHub {
      owner = "boostorg";
      repo = "pfr";
      rev = "b0bf18798c7037ca8a91a1cd2ad2e5798d8f6d46";
      hash = "sha256-vKk4cAkbAEqCOjOukWQC8NoYixgA3bgXgzqWprc2hM0=";
    };
  };
in stdenv.mkDerivation rec {
  pname = "open-hexagon";
  version = "unstable-2023-04-21";
  src = fetchFromGitHub {
    owner = "SuperV1234";
    repo = "SSVOpenHexagon";
    rev = "1e2cba71242ab149d548abdb54d3bceb92c33922";
    fetchSubmodules = true;
    sha256 = "sha256-7H4DmzlByNBI9uke2m01hxPYFootIPwcKl/Iu2VsKyQ=";
  };
  # cmakelist = builtins.readFile ../CMakeLists.txt;

  nativeBuildInputs = [ cmake cpm-cmake ];

  buildInputs = [ libsodium freetype libXfixes libXext libXrandr libXcursor libGL systemdLibs openal libvorbis flac ];

  # desktopItems = [
  #   (makeDesktopItem {
  #     name = "open-hexagon";
  #     exec = "open-hexagon";
  #     icon = "open-hexagon";
  #     desktopName = "Open Hexagon";
  #     comment = meta.description;
  #     type = "Application";
  #     categories = [ "Game" "ArcadeGame" ];
  #     startupWMClass = "SSVOpenHexagon";
  #   })
  # ];
  cmakeFlags = [
    "-DCPM_SOURCE_CACHE=cmake"
    "-DCPM_SFML_SOURCE=../SFML"
    "-DCPM_luajit_SOURCE=${luajit.src}"
    "-DCPM_zlib_SOURCE=../zlib"
    "-DCPM_imgui_SOURCE=${imgui.src}"
    "-DCPM_imgui-sfml_SOURCE=${imgui-sfml.src}"
    "-DCPM_libsodium-cmake_SOURCE=${libsodium}"
    "-DCPM_boostpfr_SOURCE=${boostpfr.src}"
  ];

  cmakeBuildDir = "buildlx";

  patches = [
    ./dont-set-working-directory.patch
  ];

  preConfigure = ''
    mkdir -p cmake/cpm
    cp ${cpm-cmake}/share/cpm/CPM.cmake cmake/cpm/CPM_0.37.0.cmake
    sed -i 's/file(WRITE.*zlib_SOURCE_DIR.*CMakeLists.txt.*//g' CMakeLists.txt
    cp -R --no-preserve=mode,ownership ${SFML.src} SFML
    cp -R --no-preserve=mode,ownership ${zlib.src} zlib
    pushd SFML/include/SFML
    sed -i '1i #include <cstdint>' System/Utf.hpp System/String.hpp Network/Packet.hpp
    popd
    sed -i 's/=.*\/@CMAKE_INSTALL_LIBDIR@/=@CMAKE_INSTALL_FULL_LIBDIR@/g' zlib/zlib.pc.cmakein
    sed -i 's/=.*\/@CMAKE_INSTALL_INCLUDEDIR@/=@CMAKE_INSTALL_FULL_INCLUDEDIR@/g' zlib/zlib.pc.cmakein
    sed -i 's/=.*\/@CMAKE_INSTALL_LIBDIR@/=@CMAKE_INSTALL_FULL_LIBDIR@/g' SFML/tools/pkg-config/*.pc.in
  '';

  postInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/lib
    mkdir -p $out/share
    mv $TMP/$sourceRoot/_RELEASE/libsteam_api.so $out/lib/
    mv $TMP/$sourceRoot/_RELEASE/libdiscord_game_sdk.so $out/lib/
    mv $TMP/$sourceRoot/_RELEASE/libsdkencryptedappticket.so $out/lib/
    mv $TMP/$sourceRoot/_RELEASE $out/share/
    echo "#!/bin/bash" > $out/bin/open-hexagon
    echo "if [ ! -d ~/.local/share/open-hexagon ]; then" >> $out/bin/open-hexagon
    echo "mkdir -p ~/.local/share/open-hexagon" >> $out/bin/open-hexagon
    echo "cp -R --no-preserve=mode,ownership $out/share/_RELEASE/Assets ~/.local/share/open-hexagon/Assets" >> $out/bin/open-hexagon
    echo "cp -R --no-preserve=mode,ownership $out/share/_RELEASE/ConfigOverrides ~/.local/share/open-hexagon/ConfigOverrides" >> $out/bin/open-hexagon
    echo "cp -R --no-preserve=mode,ownership $out/share/_RELEASE/Packs ~/.local/share/open-hexagon/Packs" >> $out/bin/open-hexagon
    echo "fi" >> $out/bin/open-hexagon
    echo "cd ~/.local/share/open-hexagon" >> $out/bin/open-hexagon
    echo "$out/share/_RELEASE/SSVOpenHexagon" >> $out/bin/open-hexagon
    chmod +x $out/bin/open-hexagon
  '';

  # postUnpack = let

  #   split-cmakelist = (cpm_pkg: input_cmakelist: builtins.split "(CPMAddPackage\\([^)]*NAME ${cpm_pkg}[^)]*\\))" input_cmakelist);
  #   update-cmakelist = (cpm_pkg: input_cmakelist: lib.strings.concatStrings [
  #     (lib.lists.last (lib.lists.take 1 (split-cmakelist cpm_pkg input_cmakelist)))
  #     "add_subdirectory(${cpm_pkg})"
  #     (lib.lists.last (split-cmakelist cpm_pkg input_cmakelist))
  #   ]);
  #   cpm_pkgs = [ "luajit" "SFML" "zlib" "imgui-sfml" "libsodium-cmake" "boostpfr" ];
  #   newcmakelist = builtins.foldl' (acc: elem: (update-cmakelist elem acc)) cmakelist cpm_pkgs;
  # in
  #   ''
  #     (
  #       cd "$sourceRoot"
  #       cp -R --no-preserve=mode,ownership ${luajit.src} luajit
  #       cp -R --no-preserve=mode,ownership ${SFML.src} SFML
  #       cp -R --no-preserve=mode,ownership ${zlib.src} zlib
  #       cp -R --no-preserve=mode,ownership ${imgui.src} imgui
  #       cp -R --no-preserve=mode,ownership ${imgui-sfml.src} imgui-sfml
  #       cp -R --no-preserve=mode,ownership ${libsodium-cmake.src} libsodium-cmake
  #       cp -R --no-preserve=mode,ownership ${boostpfr.src} boostpfr
  #       echo '${newcmakelist}' > CMakeLists.txt
  #       cat CMakeLists.txt
  #       patchShebangs .
  #     )
  #   '';

}
