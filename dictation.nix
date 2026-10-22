{ pkgs, ... }:

# Local live dictation: $mod+` (see ~/.config/i3/config) starts
# recording; each phrase is transcribed by whisper.cpp on the GPU and typed
# into the focused window when you pause. Press it again to stop.
let
  # CUDA build for the RTX 2080 Ti only (sm_75) to keep compile times down.
  whisper = pkgs.pkgsForCudaArch.sm_75.whisper-cpp;

  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
    hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
  };

  port = "8178";

  # Types each phrase as soon as you pause; see dictate.py.
  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      python3
      pipewire
      xdotool
      polybar
    ];
    text = ''
      export DICTATE_URL="http://127.0.0.1:${port}/inference"
      exec python3 ${./dictate.py} "$@" 2>>"''${XDG_RUNTIME_DIR:-/tmp}/dictate.log"
    '';
  };
in
{
  home.packages = [
    dictate
    whisper
  ];

  # Keeps the model resident on the GPU so transcription starts instantly.
  systemd.user.services.whisper-server = {
    Unit.Description = "whisper.cpp server for dictation";
    Service = {
      ExecStart = "${whisper}/bin/whisper-server --host 127.0.0.1 --port ${port} -m ${model} -l en";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
