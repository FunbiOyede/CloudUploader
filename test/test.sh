result=$?
echo "$result"

if [[ "$result" == 0 ]]; then
    echo "Yellow Pawpaw"
else
    echo "Black Mane"
    exit 1
fi