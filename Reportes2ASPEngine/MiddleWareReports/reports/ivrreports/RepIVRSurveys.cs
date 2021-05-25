using System.Data;

namespace MiddleWareReports
{
    public class RepIVRSurveys : GenericReport
    {
        protected override DataTable GetDefaultFilters(int type, DataTable catalog)
        {
            switch (type)
            {
                case 1:
                case 7:
                    DataRow row = catalog.NewRow();
                    row["dbColumn"] = type == 1 ? "campaignId" : "inboundId";
                    row["description"] = type == 1 ? "systemTranslated_NoCampaign" : "systemTranslated_NoACDGroup";
                    row["id"] = 0;
                    catalog.Rows.Add(row);
                    return catalog;

                default:
                    return base.GetDefaultFilters(type, catalog);
            }
        }
    }
}