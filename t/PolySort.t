use Sort::PolySort;
$Sort::PolySort::DEBUG=0;
$s=new Sort::PolySort;

print "1..4\n";

%s=$s->get;		# %s is 'name'
$s->by('ip');		# builtin is 'ip'

warn("\tby('ip'), sort(\@list)...\n");
@in =('128.148.128.9','127.0.0.1','18.148.128.11','128.148.128.11');
@out=('18.148.128.11','127.0.0.1','128.148.128.9','128.148.128.11');
@is =$s->sort(@in);
&check;

$s->set(%s);		# builtin is 'name'

warn("\tsortby('datebr',\@list)...\n");
@in =('20/12/73','20/11/73','21/11/73','20/11/75');
@out=('20/11/73','21/11/73','20/12/73','20/11/75');
@is =$s->sortby('datebr',@in);
&check;

warn("\t\%s=get(), set(\%s), sort(\@list)...\n");
@in =('john doe','Jane Doll','John Quasimodo Doe');
@out=('john doe','John Quasimodo Doe','Jane Doll');
@is =$s->sort(@in);
&check;

sub check {
    print "not ok\n",return if @out != @is;
    $failed=0;
    for ($i=$[;$i<=$#out;$i++) {
	$failed=1,last unless $out[$i] eq $is[$i];
    };
    $failed ? print "not ok\n" : print "ok\n";
}


