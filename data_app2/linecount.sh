tot=0
for f in  $(find ./lib/ -name '*.dart' ! -name '*.g.dart'); do
    c=$(wc -l < "$f")
    echo "$c <- $f"
    tot=$((tot+c))
done

echo "---------------------------------"
echo $tot