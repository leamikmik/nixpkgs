{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cargo-tauri,
  sable,
  desktop-file-utils,
  xdg-utils,
  wrapGAppsHook4,
  makeBinaryWrapper,
  pkg-config,
  openssl,
  glib-networking,
  webkitgtk_4_1,
  jq,
  moreutils,
  libayatana-appindicator,
  gst_all_1,
  gobject-introspection,
  at-spi2-atk,
  atkmm,
  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  gsettings-desktop-schemas,
  harfbuzz,
  librsvg,
  libsoup_3,
  pango,
  nix-update-script,
  _experimental-update-script-combinators,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sable-desktop";
  # We have to be using the same version as cinny-web or this isn't going to work.
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    rev = "01d5cdc";
    hash = "sha256-Xz9jBwODL59qjfBGi2i5ZsogFi1whJgVJT+Yf0CUVP4=";
  };

  sourceRoot = "${finalAttrs.src.name}/src-tauri";

  cargoHash = "sha256-n5tplxbUcKOgThvkaJNs439W2003TwSjt28qxYQdQj0=";

  postPatch =
    let
      sable' =
        assert lib.assertMsg (
          sable.version == finalAttrs.version
        ) "sable.version (${sable.version}) != sable-desktop.version (${finalAttrs.version})";
        sable.override {
          conf = {
            hashRouter.enabled = true;
          };
        };
    in
    ''
      ${lib.getExe jq} \
        'del(.plugins.tauri.updater) | .build.frontendDist = "${sable'}" | del(.build.beforeBuildCommand) | .bundle.createUpdaterArtifacts = false' tauri.conf.json \
        | ${lib.getExe' moreutils "sponge"} tauri.conf.json
    '';

  preBuild = lib.optionalString stdenv.hostPlatform.isDarwin "
    export XDG_DATA_DIRS='$GSETTINGS_SCHEMAS_PATH:$XDG_DATA_DIRS'
    export GIO_EXTRA_MODULES='${glib-networking}/lib/gio/modules'
    export GST_PLUGIN_SYSTEM_PATH='${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0'
  ";

  postInstall =
    lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p "$out/bin"
      makeWrapper "$out/Applications/sable.app/Contents/MacOS/sable" "$out/bin/sable"
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      desktop-file-edit \
        --set-comment "Yet another matrix client for desktop" \
        --set-key="Categories" --set-value="Network;InstantMessaging;" \
        $out/share/applications/sable.desktop
    '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set-default WEBKIT_DISABLE_DMABUF_RENDERER "1"
      --prefix PATH : ${lib.makeBinPath [
        xdg-utils
        desktop-file-utils
      ]}
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libayatana-appindicator ]}
    )
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    desktop-file-utils
    pkg-config
    xdg-utils
    wrapGAppsHook4
    gobject-introspection
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    makeBinaryWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    at-spi2-atk
    atkmm
    cairo
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    gsettings-desktop-schemas
    harfbuzz
    librsvg
    libsoup_3
    pango
    webkitgtk_4_1
    openssl
    libayatana-appindicator
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

   passthru = {
    updateScript = _experimental-update-script-combinators.sequence [
      (nix-update-script { attrPath = "sable-unwrapped"; })
      (nix-update-script { })
    ];
  };

  meta = {
    description = "Yet another matrix client for desktop, but better";
    homepage = "https://github.com/SableClient/Sable";
    maintainers = with lib.maintainers; [
      leamikmik
    ];
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "sable";
  };
})
