{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  glslang,
  shaderc,
  vulkan-headers,
  vulkan-loader,
  vulkan-utility-libraries,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "low-latency-layer";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "Korthos-Software";
    repo = "low_latency_layer";
    rev = "v${finalAttrs.version}";
    hash = "sha256-mnGAH0m19wOkWEowpcPRHXQSc6HGYW+CFYxjPF2onk4=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    glslang
    shaderc
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    vulkan-utility-libraries
  ];

  meta = {
    description = "Vulkan layer for hardware agnostic input latency reduction";
    homepage = "https://github.com/Korthos-Software/low_latency_layer";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ lonerOrz ];
  };
})
