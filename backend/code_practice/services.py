import os
import sys
import tempfile
import time
import subprocess


def normalize_output(text):
    if not text:
        return ""
    text = text.replace("\r\n", "\n")
    lines = text.split("\n")
    lines = [line.rstrip() for line in lines]
    output = "\n".join(lines)
    output = output.strip("\n")
    return output


BLOCKED_PATTERNS = [
    "os.system",
    "subprocess",
    "shutil",
    "socket",
    "__import__",
    "eval(",
    "exec(",
    "open(",
    "pathlib",
]


def check_code_safety(code):
    lowered = code.lower()
    for pattern in BLOCKED_PATTERNS:
        if pattern.lower() in lowered:
            return False, f"Blocked: your code contains '{pattern}' which is not allowed."
    return True, ""


def execute_python_code(code, user_input=""):
    safe, reason = check_code_safety(code)
    if not safe:
        return {
            "success": False,
            "stdout": "",
            "stderr": reason,
            "timed_out": False,
            "execution_time_ms": 0,
        }

    tmp_file = None
    try:
        tmp_file = tempfile.NamedTemporaryFile(
            mode="w",
            suffix=".py",
            delete=False,
            encoding="utf-8",
        )
        tmp_file.write(code)
        tmp_file.close()

        start = time.perf_counter()
        result = subprocess.run(
            [sys.executable, tmp_file.name],
            input=user_input or "",
            text=True,
            capture_output=True,
            timeout=3,
        )
        elapsed = int((time.perf_counter() - start) * 1000)

        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "timed_out": False,
            "execution_time_ms": elapsed,
        }

    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "stdout": "",
            "stderr": "Execution timed out after 3 seconds.",
            "timed_out": True,
            "execution_time_ms": 3000,
        }

    except Exception as exc:
        return {
            "success": False,
            "stdout": "",
            "stderr": str(exc),
            "timed_out": False,
            "execution_time_ms": 0,
        }

    finally:
        if tmp_file and os.path.exists(tmp_file.name):
            os.unlink(tmp_file.name)


def judge_submission(code, test_input, expected_output):
    result = execute_python_code(code, user_input=test_input)

    actual_normalized = normalize_output(result["stdout"])
    expected_normalized = normalize_output(expected_output)

    if result["timed_out"]:
        passed = False
        error_message = "Execution timed out after 3 seconds."
    elif result["stderr"]:
        passed = False
        error_message = result["stderr"]
    else:
        passed = actual_normalized == expected_normalized
        error_message = None if passed else "Output did not match expected result"

    return {
        "actual_output": result["stdout"],
        "expected_output": expected_output,
        "stderr_output": result["stderr"],
        "passed": passed,
        "execution_time_ms": result["execution_time_ms"],
        "timed_out": result["timed_out"],
        "error_message": error_message,
    }
