#!/bin/bash
#
# author: Mehmet ASLAN
# date: May 17, 2017
#
# no warranty, no licence agreement
# use it at your own risk
#
# please use more recent version
# older version here if mess up

# alias osiplot='osiplot $(pwd)'

path=$1
# this is the path script called from

if [ -z $path ]
then
    echo determine path
fi

cd $path

if [ ! $(ls | grep .csv | wc -l) -gt 0 ]
then
    echo csv not exist
    exit 1
fi

tmp_dir='/tmp/osiplot'

i='0'

while true
do
    if [ -d "$tmp_dir$i" ]
    then
	i=$(( $i + 1 ))
    else
	tmp_dir=$tmp_dir$i
	mkdir $tmp_dir
	break
    fi
done

for i in $(ls | grep .csv)
do
    txt=${i/%csv/txt}

    if [ -e $txt ]
    then
	cp ./$txt ./$i $tmp_dir
    else
	echo $txt is missing
    fi
done

function unit_converter {
    in=$1
    unit=$(echo $in | sed 's/[0-9.-]*//')
    number=${in:0:${#in}-${#unit}}
    first=${unit:0:1}

    coef=
    case $first in
	u)
	    coef=e-06
	    ;;
	m)
	    coef=e-03
	    ;;
	V|s)
	    coef=e+00
	    ;;
    esac

    echo $number$coef
}

file=' '

# row col
function get {
    row=$(cat $file.tr | sed -n "$1p")
    echo $(echo $row | cut -d ' ' -f $2)
}

function get_n_convert {
    echo $(unit_converter $(get $*))
}

# row enough
function coupling {
    coup=$(get $1 5)
    
    if [ ${coup:0:1} = A ]
    then
	coup="\\~"
    else
	coup=' '
    fi

    echo $coup
}

cd $tmp_dir

for i in $(ls *.txt)
do
    file=$(echo $i | cut -d '.' -f 1)
    dos2unix -q -n $file.txt $file.txt
    dos2unix -q -n $file.csv $file.csv
    
    # remove repeating white spaces
    tr --squeeze-repeats ' ' < $i > $file.tr

    chx=$(head -n 1 $file.csv | wc -m)

    start=$(head -n 3 $file.csv | tail -n 1 | cut -d ',' -f 1)
    stop=$(tail -n 1 $file.csv | cut -d ',' -f 1)

    x1="set xrange [$start:$stop]"

    sed -i '2c\' $file.csv

    row=4
    col=6
    
    vs1=$(get_n_convert 2 3)
    vp1=$(get_n_convert 2 4)
    n1=$(get  2 1)

    n1="$n1$(coupling 2) ${vs1} V"
    
    vt1=$vs1*$row-$vp1
    vb1=$vs1*-$row-$vp1
    
    p1="plot '$file.csv' u 1:2 w l lt 1 lw 1 axes x1y1 t '$n1'"
    y1="set yrange [$vb1:$vt1]"
    yt="set ytics $vb1,$vs1,$vt1 textcolor \"white\""
    
    
    time=$(get_n_convert 8 3)
    delay=$(get_n_convert 8 4)
    
    if [ $chx -gt 7 ]
    then
	# ch2 exist
	vs2=$(get_n_convert 3 3)
	vp2=$(get_n_convert 3 4)
	n2=$(get  3 1)

	n2="$n2$(coupling 3) ${vs2} V"

	delay=$(get_n_convert 10 4)
	time=$(get_n_convert 10 3)

	vt2=$vs2*$row-$vp2
	vb2=$vs2*-$row-$vp2

	p2=", '$file.csv' u 1:3 w l lt 1 lw 2 axes x1y2 t '$n2'"
	y2="set y2range [$vb2:$vt2]"

	ar2="set arrow from second $start-$time/2,0 length $time/2 angle 0 lt 1 lw 2"
    fi

    xt="set xtics $start,$time,$stop textcolor \"white\""
    mvl="set arrow from $delay,$vb1 to $delay,$vt1 nohead lt 6 lc \"yellow\""
    mhl="set arrow from $start,-$vp1 to $stop,-$vp1 nohead lt 6 lc \"yellow\""

    ar1="set arrow from $start-$time/2,0 length $time/2 angle 0 lt 1 lw 1"
    art="set arrow from 0,$vt1+$vs1/2 to 0,$vt1 lt 1 lw 1"

    key="set key title '$time s' at $stop,$vb1 font ',10'"
    link="set label 'github.com/aslan-mehmet/osiplot' at $start,$vb1-$vs1/5 font ',10'"
    
    echo  $file $n1 $vs1 $vp1 $n2 $vs2 $vp2 $time $delay $start $stop

    echo "
set datafile separator ','
$x1
$y1
$y2

$xt
$yt
set grid

$mvl
$mhl

$ar1
$ar2
$art

$key
$link
set margin 3,3,3,3

set terminal pdf color size 21cm,14.8cm
set output '$file.pdf'
$p1$p2
quit
" > $file.plt
    
    gnuplot -e "load '$file.plt'"
done

cp *.pdf $path

if [ ! -z $tmp_dir ]
then
    rm -r $tmp_dir
fi
