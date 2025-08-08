# docker file for benchmark

## using benchmark docker

### step 1. clone repo
```
git clone https://github.com/zzycarrot/JsBenchmarkDocker.git
cd JsBenchmarkDocker
git clone -b docker https://github.com/zzycarrot/ossf-cve-benchmark.git
```
- `config.json` is for configuring analyzer tool
```json
{
  "tools": {
    "secanalyzer-default": {
      "bin": "node",
      "args": [
        "/ossf/build/ts/contrib/tools/secanalyzer/src/secanalyzer.js"
      ],
      "options": {
        "secanalyzerDir": "/ossf/${ANALYZER_PATH}"
      }
    }
  }
}
```
- clone secanalyzer to `ANALYZER_PATH`, (`ANALYZER_PATH = "contrib\tools\secanalyzer\.." `for example)
### step 2. build docker image
```
docker build --progress=plain -t jsbenchmark .
```
### step 3. run analyzer
- run single test unit
```
docker run -it --name benchmark jsbenchmark run --config /ossf/config.json --tool nodejsscan-default CVE-2018-3713
```
- run all tests 
```
docker run -it --name benchmark jsbenchmark run --config /ossf/config.json --tool nodejsscan-default "*"
```
- (you can use `docker rm -f benchmark` to delete)
### step 4. save snapshot
```
docker commit jsbenchmark benchmark-snapshot
```
### step 5. get report 
- you can view report on `http://127.0.0.1:8081/`
```
docker run -p 8081:8080 --rm --name benchmarknew1 benchmark-snapshot report --kind server --tool nodejsscan-default "*"
``` 
### Debuging
```
docker build --progress=plain -t debug-image
docker run -it --entrypoint=/bin/sh debug-image 
```
or
```
docker commit jsbenchmark debug-image
docker run -it --entrypoint=/bin/sh debug-image 
```