use LWP::UserAgent;
use HTML::TreeBuilder;
use HTML::Element;
use HTML::Parser;
use LWP::Simple;
use URI;
use Encode;
use HTTP::Cookies;
###########################################################
###1，首先构造一系列网页地址
###########################################################
@list_url=();
@download_url=();
foreach (1..3)#首先自己看看需要爬多少个页面
        {
         my $url = URI->new('http://npd.nsfc.gov.cn/fundingProjectSearchAction!search.action');
         my($field,$page) = ("B",$_);#对C这个领域做查询，页面累积变化
         $url->query_form
         (
           # All form pairs:
           'fundingProject.applyCode'  => $field, #搜索的领域，此处固定为C，是生命科学的代码
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


#接下来访问所有的页面，一个个爬取信息
foreach (@list_url)#对我们自己合成的目标url做循环爬取适合的链接
          {
          my $response = $tmp_ua->get($_);
          $html=$response->content;# 得到原始html文件源代码
		  my $tree = HTML::TreeBuilder->new; # empty tree
          $tree->parse($html) or print "error : parse html ";#$tree 为指向$html的hash变量
		  @dl_list=$tree->look_down(_tag,'dl') or print "error : cannot find time_dl";#成功找到dl
		  
	foreach (@dl_list)
      {
	  print FH $_->as_text()."\n";#
      }
}

