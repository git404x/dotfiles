import json
import os
import socket
import subprocess
import sys
import time
from typing import Dict, Optional

MODEL_CATALOG: Dict[str, Dict[str, Dict[str, str]]] = {
    "General": {
        "gemini-2.5-pro": {
            "id": "gemini/gemini-2.5-pro",
            "display": "Gemini 2.5 Pro",
        },
        "gemini-3.5-flash": {
            "id": "gemini/gemini-3.5-flash",
            "display": "Next-Gen Speed & Reasoning",
        },
        "gemini-3.1-flash-lite": {
            "id": "gemini/gemini-3.1-flash-lite",
            "display": "Ultra-Low Latency Edge Agent",
        },
        "gemini-3-flash-preview": {
            "id": "gemini/gemini-3-flash-preview",
            "display": "Experimental Capabilities Build",
        },
    },
    "Code": {
        "gemini-3.1-pro": {
            "id": "gemini/gemini-3.1-pro",
            "display": "Gemini 3.1 Pro (Advanced Reasoning)",
        },
        "gemini-2.5-pro": {
            "id": "gemini/gemini-2.5-pro",
            "display": "Gemini 2.5 Pro (Deep Context)",
        },
        "gemini-3.5-flash": {
            "id": "gemini/gemini-3.5-flash",
            "display": "Primary Logic & Refactoring",
        },
        "gemini-3.1-flash-lite": {
            "id": "gemini/gemini-3.1-flash-lite",
            "display": "Fast Boilerplate & Syntax Gen",
        },
        "gemini-3-flash-preview": {
            "id": "gemini/gemini-3-flash-preview",
            "display": "Experimental Deep Context Code",
        },
    },
    "Image": {
        "gemini-3.1-flash-image": {
            "id": "gemini/gemini-3.1-flash-image",
            "display": "Fast Multimodal Visual Gen",
        },
        "gemini-3-pro-image": {
            "id": "gemini/gemini-3-pro-image",
            "display": "High-Fidelity Studio Fab",
        },
        "gemini-2.5-flash-image": {
            "id": "gemini/gemini-2.5-flash-image",
            "display": "Legacy Stable Vision Gen",
        },
    },
    "Video": {
        "veo-3.1-generate-preview": {
            "id": "gemini/veo-3.1-generate-preview",
            "display": "Experimental Timeline/Video Fab",
        },
    },
    "Others": {
        "gemini-3.1-flash-live-preview": {
            "id": "gemini/gemini-3.1-flash-live-preview",
            "display": "Real-time Streaming Matrix",
        },
        "gemini-3.1-flash-tts-preview": {
            "id": "gemini/gemini-3.1-flash-tts-preview",
            "display": "Text-to-Speech Audio Fab",
        },
    },
}


def check_socket(port: int) -> bool:
    """Evaluate loopback interface bindings."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def parse_selection_matrix() -> Optional[Dict[str, str]]:
    """Flatten dictionary into a clean CLI interface via fzf."""
    lines = []
    for category, models in MODEL_CATALOG.items():
        for key, meta in models.items():
            c_pad = category.ljust(8)
            k_pad = key.ljust(30)
            disp = meta["display"]
            lines.append(f"[{c_pad}] {k_pad} :: {disp}")

    # Magic commas added here
    fzf_cmd = [
        "fzf",
        "--reverse",
        "--height=45%",
        "--prompt=Target AI Core > ",
        "--border=rounded",
    ]

    try:
        fzf = subprocess.Popen(
            fzf_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        stdout, _ = fzf.communicate(input="\n".join(lines))
        if not stdout:
            print("[!] Sequence aborted.")
            sys.exit(0)

        sel_str = stdout.split("] ")[1]
        selected_key = sel_str.split(" ::")[0].strip()

        for models in MODEL_CATALOG.values():
            if selected_key in models:
                return models[selected_key]
        return None

    except FileNotFoundError:
        print("[-] Fatal: 'fzf' missing from injected PATH.")
        sys.exit(1)
    except IndexError:
        print("[-] Fatal: Parsing error during UI extraction.")
        sys.exit(1)


def main() -> None:
    selected = parse_selection_matrix()
    if not selected:
        sys.exit(1)

    target_id = selected["id"]
    primary_port = 4000
    fallback_port = 5000

    active_port: Optional[int] = None
    proxy: Optional[subprocess.Popen[bytes]] = None
    config_path = "/tmp/litellm_workspace_config.json"

    if check_socket(primary_port):
        m = f"[✓] Proxy found on {primary_port}. Reusing tunnel..."
        print(m)
        active_port = primary_port
    elif check_socket(fallback_port):
        m = f"[!] Primary occupied. Engaging port {fallback_port}..."
        print(m)
        active_port = fallback_port
    else:
        m = f"[+] Bootstrapping translation layer for {target_id}..."
        print(m)

        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print("[-] Fatal: GEMINI_API_KEY env var is missing.")
            sys.exit(1)

        config_data = {
            "model_list": [
                {
                    "model_name": target_id,
                    "litellm_params": {
                        "model": target_id,
                        "api_key": api_key,
                        "timeout": 600,
                    },
                },
            ],
            # intercept & drop api params
            "litellm_settings": {
                "drop_params": True,
            },
        }

        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config_data, f)

        # Magic commas force Neovim to leave this array alone
        proxy_cmd = [
            "litellm",
            "--config",
            config_path,
            "--port",
            str(primary_port),
        ]

        proxy = subprocess.Popen(
            proxy_cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(1.5)
        active_port = primary_port

    os.environ["ANTHROPIC_BASE_URL"] = f"http://127.0.0.1:{active_port}"
    os.environ["CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY"] = "1"
    print("[+] Context Bound. Handing off to AI Agent...")

    try:
        subprocess.run(["claude", "--model", target_id], check=True)
    except KeyboardInterrupt:
        pass
    except subprocess.CalledProcessError as e:
        print(f"[-] Agent process terminated with error: {e}")
    finally:
        if proxy is not None:
            print("[+] Purging proxy and telemetry buffers...")
            proxy.terminate()
            proxy.wait()

        if os.path.exists(config_path):
            os.remove(config_path)


if __name__ == "__main__":
    main()
