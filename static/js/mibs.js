(function ($) {
    "use strict";


    /*==================================================================
    [ Focus Contact2 ]*/
    $('.input100').each(function(){
        $(this).on('blur', function(){
            if($(this).val().trim() != "") {
                $(this).addClass('has-val');
            }
            else {
                $(this).removeClass('has-val');
            }
        })
    })

    /*==================================================================
    [ Validate ]*/
    var oidNumber = $('.validate-input input[name="oidNumber"]');
    var oidIp = $('.validate-input input[name="oidIp"]');
    console.log(oidIp);
    var oidDescription = $('.validate-input input[name="oidDescription"]');
    var oidInputP = $('.validate-input input[name="oidInputP"]');
    var oidOutputP = $('.validate-input input[name="oidOutputP"]');


    $('.validate-form').on('submit',function(){

        var check = true;

        if($(oidNumber).val().trim() == ''){
            showValidate(oidNumber);
            check=false;
        }

        if($(oidIp).val().trim() == ''){
            showValidate(oidIp);
            check=false;
        }

        if($(oidDescription).val().trim() == ''){
            showValidate(oidDescription);
            check=false;
        }

        if($(oidInputP).val().trim() == ''){
            showValidate(oidInputP);
            check=false;
        }

        if($(oidOutputP).val().trim() == ''){
            showValidate(oidOutputP);
            check=false;
        }

        return check;
    });


    $('.validate-form .input100').each(function(){
        $(this).focus(function(){
           hideValidate(this);
       });
    });

    function showValidate(input) {
        var thisAlert = $(input).parent();
        $(thisAlert).addClass('alert-validate');
    }

    function hideValidate(input) {
        var thisAlert = $(input).parent();
        $(thisAlert).removeClass('alert-validate');
    }

})(jQuery);