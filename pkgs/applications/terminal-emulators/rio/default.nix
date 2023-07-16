{ lib
, fetchFromGitHub
, rustPlatform
, nix-update-script

, autoPatchelfHook
, ncurses
, pkg-config

, gcc-unwrapped
, fontconfig
, libGL
, vulkan-loader
, libxkbcommon

, withX11 ? true
, libX11
, libXcursor
, libXi
, libXrandr
, libxcb

, withWayland ? true
, wayland
}:
let
  rlinkLibs = [
    (lib.getLib gcc-unwrapped)
    fontconfig
    libGL
    libxkbcommon
    vulkan-loader
  ] ++ lib.optionals withX11 [
    libX11
    libXcursor
    libXi
    libXrandr
    libxcb
  ] ++ lib.optionals withWayland [
    wayland
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "rio";
  version = "0.0.8";

  src = fetchFromGitHub {
    owner = "raphamorim";
    repo = "rio";
    rev = "v${version}";
    hash = "sha256-NonIMGBASbkbc5JsHKwfaZ9dGQt1f8+hFh/FFyIlIZs=";
  };

  cargoHash = "sha256-4IJJtLa25aZkFwkMYpnYyRQLeqoBwncgCjorF6Gx6pk=";

  nativeBuildInputs = [
    autoPatchelfHook
    ncurses
    pkg-config
  ];

  runtimeDependencies = rlinkLibs;

  buildInputs = rlinkLibs;

  outputs = [ "out" "terminfo" ];

  buildNoDefaultFeatures = true;
  buildFeatures = [
    (lib.optionalString withX11 "x11")
    (lib.optionalString withWayland "wayland")
  ];

  postInstall = ''
    install -dm 755 "$terminfo/share/terminfo/r/"
    tic -xe rio,rio-direct -o "$terminfo/share/terminfo" misc/rio.terminfo
    mkdir -p $out/nix-support
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version-regex" "v([0-9.]+)" ];
    };
  };

  meta = {
    description = "A hardware-accelerated GPU terminal emulator powered by WebGPU";
    homepage = "https://raphamorim.io/rio";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ otavio oluceps ];
    platforms = lib.platforms.unix;
    changelog = "https://github.com/raphamorim/rio/blob/v${version}/CHANGELOG.md";
  };
}
