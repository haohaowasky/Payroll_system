# Status_Review

What I understand about this project is

I suppose there are different options of tokens that employee can chose to be paid. This is what
token[] allowed means. and also the payroll allocation function needs.

** Ethereum payment **

this is the part I got confused, since employee's are getting paid by tokens, what's the point
for refill ethereum. So I still keep the function but it is just sitting there alone. I guess employee's
could get paid in ethereum, and couple functions can be added to make it happen.


** Timing Problem **

the "now" only take time stamp in seconds, so it will be time offset in month. To solve it, a function
can take a 12 elements of array which stands for each day of month, and than multiply the seconds in
day. I found it is possible but very complicated, the best way is just to have oracle to set the time.

** Except those, it is all good ! **

I cannot test this because I don't have the address of the tokens.
But I tested it when I get rid of the token and oracle, only test it in ethereum in Remix test net. 
