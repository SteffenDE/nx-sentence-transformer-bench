# Python vs. Elixir Nx Sentence Transformers Benchmark

Some benchmarks of the encoding performance of a sentence-transformer model using Python and Elixir.
I ran these tests on my MacBook Pro with M1 Max (CPU only, so M1 Pro should be the same).

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
    Latency   571.15ms   47.34ms   1.04s    99.05%
    Req/Sec     6.47      1.76    30.00     97.64%
  3360 requests in 1.00m, 423.28KB read
Requests/sec:     55.93
Transfer/sec:      7.05KB
```

So we achieve ~half the performance of the simple Python server with more than double the latency.
The Activity Monitor only shows ~300% cpu usage, although the BEAM should be able to use all cores.
Let's try to start multiple `Nx.Serving` processes to see if this improves the performance.

```bash
$ elixir nx_multi_serving.exs
```

```
$ wrk http://127.0.0.1:5001 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:5001
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   811.61ms  167.04ms   1.26s    57.33%
    Req/Sec     6.38      4.89    30.00     85.30%
  2348 requests in 1.00m, 295.79KB read
Requests/sec:     39.06
Transfer/sec:      4.92KB
```

Nope, that's worse. Let's try to run multiple BEAM instances instead:

```bash
$ ./multi_beam.sh
```

```
$ wrk http://127.0.0.1:6000 -t 8 -c 32 -d 60
Running 1m test @ http://127.0.0.1:6000
  8 threads and 32 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   339.33ms  103.44ms 989.52ms   78.44%
    Req/Sec    12.63      6.61    30.00     67.22%
  5688 requests in 1.00m, 0.88MB read
Requests/sec:     94.63
Transfer/sec:     15.07KB
```

That's better, but still not close to what we achieved using Python.
