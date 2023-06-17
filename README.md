# Python vs. Elixir Nx Sentence Transformers Benchmark

Some benchmarks of the encoding performance of a sentence-transformer model using Python and Elixir.
I ran these tests on my MacBook Pro with M1 Max (CPU only, so M1 Pro should be the same).

## UPDATE

In the initial results, I forgot to set the compiler option for the Nx.Serving. Doing this improves
the performance of the Nx code significantly. The updated results are below. You can find the old
results in the git history.

## Setup

For running the python server, create a virtual environment:

```bash
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip3 install sentence-transformers flask
```

Then run the server using

```bash
$ FLASK_APP=simple flask run
```

The `multi_*.sh` scripts also expect the [Caddy webserver](https://caddyserver.com/) to be installed.
On macOS, a simple `brew install caddy` will do.

## Results

I used wrk to run a simple HTTP benchmark.

### Python

Let's start with the Python server:

```bash
$ FLASK_APP=simple flask run
```

```
$ wrk http://127.0.0.1:5000 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:5001
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   275.36ms   26.36ms 420.76ms   70.38%
    Req/Sec    14.70      6.70    30.00     87.30%
  6951 requests in 1.00m, 1.15MB read
Requests/sec:    115.69
Transfer/sec:     19.66KB
```

So roughly ~110 requests per second with an average latency of 275ms.
Looking at the Activity Monitor of my MacBook showed that there is still some headroom with only ~350% usage. Starting two python servers with a caddy reverse proxy:

```bash
$ ./multi_py.sh
```

```
$ wrk http://127.0.0.1:6000 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:6000
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   173.08ms  111.59ms 628.10ms   55.31%
    Req/Sec    24.14     12.96   100.00     56.53%
  11200 requests in 1.00m, 1.82MB read
Requests/sec:    186.35
Transfer/sec:     30.94KB
```

Now we nearly achieve 200 requests per second with an even better latency of ~170ms.

### Elixir

The simplest example can be found in the `nx_serving.exs` file:

```bash
$ elixir nx_serving.exs
```

```
$ wrk http://127.0.0.1:5001 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:5001
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    27.98ms    3.23ms 117.13ms   90.78%
    Req/Sec   143.28     19.25   161.00     64.48%
  68572 requests in 1.00m, 8.44MB read
Requests/sec:   1141.16
Transfer/sec:    143.76KB
```

So we achieve nearly 10x the performance of the simple Python server with an impressively low latency.
The Activity Monitor only shows ~450% cpu usage.

Let's try to run multiple BEAM instances instead:

```bash
$ ./multi_beam.sh
```

```
$ wrk http://127.0.0.1:6000 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:6000
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   136.22ms    8.20ms 274.61ms   91.79%
    Req/Sec    32.07     10.02    40.00     65.19%
  14086 requests in 1.00m, 2.19MB read
Requests/sec:    234.37
Transfer/sec:     37.33KB
```

Interestingly, although the CPU is not fully loaded with one BEAM instance, starting another one and
load-balancing the requests does not improve the performance and actually lowers it quite significantly.
