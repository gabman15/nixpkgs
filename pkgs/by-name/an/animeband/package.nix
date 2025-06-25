{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  ncurses5,
  libX11,
  enableSdl2 ? false,
  SDL2,
  SDL2_image,
  SDL2_sound,
  SDL2_mixer,
  SDL2_ttf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "animeband";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "NickMcConnell";
    repo = "AngbandPlus";
    rev = "93978f0aa2e0b8c535d05fa8ff67e47dba880a62";
    hash = "sha256-QH2w0hWFwXyVSPhRyIVUloMfo6tAf4fS5g+LRUKUBYw=";
  };

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs =
    [ ncurses5 libX11 ];
    # ++ lib.optionals enableSdl2 [
    #   SDL2
    #   SDL2_image
    #   SDL2_sound
    #   SDL2_mixer
    #   SDL2_ttf
    # ];
  patches = [ ./no_null_set_int.patch ./extern_do_train_station.patch ];
  configureFlags = ["--with-x"];

  installFlags = [ "bindir=$(out)/bin" ];

  meta = with lib; {
    homepage = "https://nickmcconnell.github.io/AngbandPlus/animeband.html";
    description = "Single-player roguelike dungeon exploration game, with Anime!";
    maintainers = [ maintainers.kenran ];
    license = licenses.gpl2Only;
    platforms = platforms.unix;
  };
})
