 1. Start the container:
   1     ./start_podman.sh
   2. Run the tests for a specific version (inside the container):

   1     /workspace/project/scripts/run_tests.sh 29
      Replace 29 with 28 or 26 to test other versions. 

   3. Check Results:
       * Console: The script will show if the handshakes for RSA, ECC, and SM4
         were successful.
       * Logs: Detailed Common Test HTML reports are saved to your host's ./logs
         directory.
       * Certs: Generated certificates are available in ./project/certs.

  Version Support Note
   * OTP 28 & 29: Support all tests (RSA, ECC, SM4).
   * OTP 26: Will automatically skip the SM4 test as the ssl module in that
     version does not support SM4 cipher suites.
