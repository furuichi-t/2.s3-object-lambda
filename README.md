terraform学習の過程として公式ハンズオンを元に書いたソースコードです。   
公式ハンズオン:https://aws.amazon.com/jp/getting-started/hands-on/amazon-s3-object-lambda-to-dynamically-watermark-images/  
参考文献：https://qiita.com/curlneko/items/15607f8ef319cc97a75e  
  
main.tfファイルの9,44,45行でローカルのパスを指定していますが、このまま使うとエラーになります。  
ご自身のパスに変更してください。　パスは'pwd'で確認できます。  

  lambda関数を扱うディレクトリにモジュールを入れなくてはダメで、どのディレクトリに入れればいいか最初は分からなくて苦労した。。。  
  ローカルの場合は"ファイル名.py"が存在するディレクトリにモジュールを入れなければいけない。
