{
  sable-unwrapped,
  jq,
  stdenvNoCC,
  writeText,
  conf ? { },
}:
let
  configOverrides = writeText "sable-config-overrides.json" (builtins.toJSON conf);
in
if (conf == { }) then
  sable-unwrapped
else
  stdenvNoCC.mkDerivation {
    pname = "sable";
    inherit (sable-unwrapped) version meta;

    dontUnpack = true;

    nativeBuildInputs = [ jq ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ln -s ${sable-unwrapped}/* $out
      rm $out/config.json
      jq -s '.[0] * .[1]' "${sable-unwrapped}/config.json" "${configOverrides}" > "$out/config.json"

      runHook postInstall
    '';
  }