# Erlang TLS Handshake Test Suite

This project provides a testing environment for Erlang's **TLS implementation**, designed to verify handshake compatibility for different cipher suites and certificate types (RSA, ECC, and SM4) across various Erlang/OTP versions (26, 28, 29, and GmSSL).

## Current Environment
- **Base Image**: Debian stable.
- **Erlang Versions**: 26, 28, 29, and a special `gmssl` version (OTP 26 linked against GmSSL v2).

## Quick Start (Automated)
Run all tests across all Erlang versions with a single command:
```bash
./run_all_tests.sh
```
*Note: This script requires `docker-compose`. If you are using Podman, you can use `podman-compose` or the manual steps below.*

## Manual Execution
1.  **Start the development container**:
    ```bash
    docker-compose up -d --build
    ```
2.  **Run tests for a specific version**:
    ```bash
    docker-compose exec erlang-dev /workspace/project/scripts/run_tests.sh [26|28|29|gmssl]
    ```

## How the Tests Work
...

1.  **Version Switching**: `run_tests.sh` uses `switch-erlang.sh` to activate the target Erlang version. For the `gmssl` version, it also sets `LD_LIBRARY_PATH` to ensure the runtime links against the GmSSL library.
2.  **Containerized Server**: For each test case (RSA, ECC, SM4), the suite starts a temporary Podman container running the TLS server. This ensures a clean and isolated environment for the server side of the handshake.
3.  **OpenSSL Verification**: The suite uses `openssl s_client` from the host container to connect to the server container and verify the negotiated cipher suite.

## Version Support Note
- **OTP 28 & 29**: Support all tests (RSA, ECC, SM4).
- **OTP 26**: Automatically skips the SM4 test as the `ssl` module in that version does not support SM4 cipher suites.

## Results and Logs
- **Console Output**: Summarizes the test results.
- **Detailed Logs**: Comprehensive Common Test HTML reports are saved to the `/workspace/logs` directory (mapped from host).
- **Generated Certs**: Available in `/workspace/project/certs`.
