function lister($dir, $bl){
  $t = opendir($dir);

  while($fname = readdir($t)){
    $path = $dir . $fname;

    if(is_file($path)){
      if(preg_match('/(.+)\.php$/i', $fname, $match))
        print(strtr(substr($path, $bl, -strlen($match[0])), '/', '\\') . $match[1] . PHP_EOL);
    } else if(is_dir($path) && $fname != '.' && $fname != '..')
      lister($path . '/', $bl);
  }

  closedir($t);
}
$base = app_path() . '/models/';
lister($base, strlen($base));
exit;
