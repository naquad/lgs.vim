<?php

namespace Illuminate\Foundation;

class Application {
  public function detectEnvironment($envs){
    print implode(PHP_EOL, array_keys($envs)) . PHP_EOL;
    exit(0);
  }

  public function __call($unused, $unused){}
}

error_reporting(0);
require($argv[1]);
