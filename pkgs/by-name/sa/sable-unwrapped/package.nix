{
	lib,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sable-unwrapped";
  # Remember to update cinny-desktop when bumping this version.
  version = "1.15.2";

  # nixpkgs-update: no auto update
  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xExjv97z/1npGhQCAgHJk27N3BSxHqbd6o/Moe+sBV0=";
  };

  nativeBuildInputs = [
  	nodejs
  	pnpmConfigHook
  	pnpm
  ];

	pnpmDeps = fetchPnpmDeps {
		inherit (finalAttrs) pname version src;
		fetcherVersion = 3;
		hash = "sha256-9QIBOF1d7Z086IsOAHpOayKA3uNY0e5imYQixHKFXxw=";
	};

  # Skip rebuilding native modules since they're not needed for the web app
  #npmRebuildFlags = [
  #  "--ignore-scripts"
  #];

	buildPhase = ''
		runHook preBuild
		pnpm run build
		runHook postBuild
	'';

  installPhase = ''
		runHook preInstall

    cp -r dist $out
    
		runHook postInstall
  '';

  meta = {
    description = "Yet another Matrix client for the web";
    homepage = "https://github.com/SableClient/Sable";
    maintainers = with lib.maintainers; [
			leamikmik
    ];
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.all;
  };
})
