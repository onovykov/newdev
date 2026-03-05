//===== Сервіс конвертації кастомного ліда - єдина точка відповідальності
public with sharing class LeadConversionService {

    public static void convert(EnquiryContext ctx) {

        if (ctx.opportunity == null) {
            /* Тут додати лог в Тритон */
            System.debug('No opportunity to convert');
            return;
        }

        LeadConvertion.LeadConvertResult r =
            LeadConvertion.convertLead(ctx.opportunity.Id);

        if (!r.leadConverted) {
            /* Тут додати лог в Тритон */
            System.debug('Lead conversion failed');
            return;            
        }
    }
}