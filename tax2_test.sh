TAX_RATIO=1/10
echo $TAX_RATIO
echo "You entered a Tax rate of: " 
awk -vn=$TAX_RATIO 'BEGIN{print(('$TAX_RATIO')*100)" %"}'
echo "cmon. get it right, please."
