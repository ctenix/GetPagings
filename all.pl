use LWP::UserAgent;
use HTML::TreeBuilder;
use LWP::Simple;
use URI;
use Encode;
use LWP::UserAgent;
use HTTP::Cookies;
###########################################################
###1，首先构造一系列网页地址
###########################################################
@list_url=();
@download_url=();
foreach (1..2927)#首先自己看看需要爬多少个页面
        {
         my $url = URI->new('http://npd.nsfc.gov.cn/projectSearch!search.action?');
         my($field,$page) = ("C",$_);#对C这个领域做查询，页面累积变化
         $url->query_form
         (
           # All form pairs:
           'project.applyCode'  => $field, #搜索的领域，此处固定为C，是生命科学的代码
           'currentPage' => $page,
         );
         push @list_url,$url;
         }
#自己构造所有的网页地址，以便后面的浏览器访问
#map{print "$_\n"}   @list_url;   #测试了一些，网址生成没有问题
###########################################################
###2，然后构造perl的模拟浏览器
###########################################################
my $tmp_ua = LWP::UserAgent->new;    #UserAgent用来发送网页访问请求
$tmp_ua->timeout(15);                ##连接超时时间设为15秒
$tmp_ua->protocols_allowed( [ 'http', 'https' ] ); ##只允许http和https协议
$tmp_ua->agent(
"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727;.NET CLR 3.0.04506.30; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)"
  ) ; ##用来在header中告诉服务器你用的是什么"浏览器"，设置文件头的User-Agent
  my $cookie_jar = '.mozilla/firefox/bg146ia6.default/cookies.sqlite';
  $tmp_ua->cookie_jar(HTTP::Cookies->new('file'=>"$ENV{'HOME'}/$cookie_jar",'autosave'=>1));
###########################################################
###3，最后一个个爬取我们构造好的网站地址，找到相应的信息
###########################################################
open FH,">aa.txt";  #可以保存我们需要的东西
$url_index="http://npd.nsfc.gov.cn/";
 #必须要先访问一下主页并且保存cookies才能爬查询网页
my $response = $tmp_ua->get($url_index);  #访问了主页的同时也储存了cookies
#$html=$response->content;
#print encode("cp936", decode("utf8",$html));
#my $response = $tmp_ua->get($list_url[3]);
#$html=$response->content;
#print encode("cp936", decode("utf8",$html));   #经测试，可以访问每个项目页面了
#这些都只是一步一步的测试
#接下来做正事，访问所有的页面，一个个爬取信息
foreach (@list_url)#对我们自己合成的目标url做循环爬取适合的链接
          {
          my $response = $tmp_ua->get($_);
          $html=$response->content;
           my $tree = HTML::TreeBuilder->new; # empty tree
           $tree->parse($html) or print "error : parse html ";
           @dl_list=$tree->find_by_attribute("class","time_dl") or print "error : cannot find time_dl";
                  

foreach (@dl_list)
       {
       $dt_node=$_->look_down(_tag=>'dt');
       $dt_a_node=$dt_node->look_down(_tag=>'a');#dt标签里面的a是基金项目的网站介绍
       print FH $url_index.$dt_a_node->attr('href');
       print FH "\t";
       print FH encode("cp936", decode("utf8",$dt_a_node->as_text()));#基金项目的名字
       print FH "\t";
       @node=$_->look_down(_tag=>'dd'); #dd表格里面的是关于这个基金的各种描述
       map{print FH encode("cp936", decode("utf8",$_->as_text()))}@node;
       print FH "\n";
      }
}

