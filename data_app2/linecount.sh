tot=0
for f in  $(find ./lib/ ./test/ -name '*.dart' ! -name '*.g.dart'); do
    c=$(wc -l < "$f")
    echo "$c <- $f"
    tot=$((tot+c))
done

echo "---------------------------------"
echo $tot