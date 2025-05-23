{
  lib,
  stdenv,
  fetchFromGitiles,
  fetchpatch,
  meson,
  ninja,
  pkg-config,
  python3,
  aemu,
  libdrm,
  libglvnd,
  vulkan-headers,
  vulkan-loader,
  xorg,
}:

stdenv.mkDerivation {
  pname = "gfxstream";
  version = "0.1.2";

  src = fetchFromGitiles {
    url = "https://android.googlesource.com/platform/hardware/google/gfxstream";
    rev = "a29282666c0e2fdbb2c98cfe68a7c0677163ef91";
    hash = "sha256-IYXkaHZPEYIE9KW731GN6x6yRS+FYtP1zyHcaSofhIM=";
  };

  patches = [
    # Make libdrm an optional dependency, which is required to build on Darwin.
    (fetchpatch {
      url = "https://android.googlesource.com/platform/hardware/google/gfxstream/+/a8df2a3eb099b419a7b3638e68ea30b4cffb751b%5E%21/?format=TEXT";
      decode = "base64 -d";
      hash = "sha256-shjeNuxtQokscCGBKEUbOPKOWRELBAnHFNj3Y5w87Nw=";
    })
  ];

  # Ensure that meson can find an Objective-C compiler on Darwin.
  postPatch = lib.optionalString stdenv.hostPlatform.isDarwin ''
    substituteInPlace meson.build \
      --replace-fail "project('gfxstream_backend', 'cpp', 'c'" "project('gfxstream_backend', 'cpp', 'c', 'objc'"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ];
  buildInputs = [
    aemu
    libglvnd
    vulkan-headers
    vulkan-loader
    xorg.libX11
  ] ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform libdrm) [ libdrm ];

  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    NIX_LDFLAGS = toString [
      "-framework Cocoa"
      "-framework IOKit"
      "-framework IOSurface"
      "-framework OpenGL"
      "-framework QuartzCore"
      "-needed-lvulkan"
    ];
  };

  # dlopens libvulkan.
  preConfigure = lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
    mesonFlagsArray=(-Dcpp_link_args="-Wl,--push-state -Wl,--no-as-needed -lvulkan -Wl,--pop-state")
  '';

  meta = with lib; {
    homepage = "https://android.googlesource.com/platform/hardware/google/gfxstream";
    description = "Graphics Streaming Kit";
    license = licenses.free; # https://android.googlesource.com/platform/hardware/google/gfxstream/+/refs/heads/main/LICENSE
    maintainers = with maintainers; [ qyliss ];
    platforms = aemu.meta.platforms;
  };
}
