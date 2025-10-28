### {{site.mesh_product_name}} release policy

Kong adopts a structured approach to versioning its products. Kong Mesh follow a pattern of {MAJOR}.{MINOR}.{PATCH}.

{:.info}
> **Long Term Support Policy Update**
> <br><br>
> Beginning in October 2025, we plan to release 4 minor versions per year, every year: one in January, one in April, one in July, and the last one in October. 
> Each year, the first version we release will become an LTS release. 
> Starting from 2.13, we will have 1 LTS release every year, in November* of that year.
> <br><br>
> Example of planned LTS schedule for next 4 years:
> <table>
>  <thead>
>    <th>LTS Version</th>
>    <th>Planned release date</th>
>  </thead>
>  <tbody>
>    <tr>
>      <td>2.13</td>
>      <td>November 2025</td>
>    </tr>
>    <tr>
>      <td>2.17</td>
>      <td>November 2026</td>
>    </tr>
>    <tr>
>      <td>2.21</td>
>      <td>November 2027</td>
>    </tr>
>  </tbody>
> </table>
> Each LTS is supported for 2 years from the date of release. 
> This will allow adjacent LTS releases to have a support overlap of 1 year in which customers can plan their upgrades.
> <br><br>
> _* Release timeframes are subject to change._


### Bug fix guidelines
Unfortunately, all software is susceptible to bugs. Kong seeks to remedy bugs through a structured protocol as follows:

* Serious security vulnerabilities are treated with the utmost priority. See our [security vulnerability reporting and remedy policy](/gateway/vulnerabilities/), including how to report a vulnerability.

* Bugs which result in production outages or effective non-operation (such as catastrophic performance degradation) will be remedied through high priority bug fixes and provided in patch releases to the Latest Major/Minor Version Release of all currently supported Major Versions of the software and optionally ported to other versions at Kong’s discretion based on the severity and impact of the bug.

* Bugs which prevent the upgrade of a supported version to a more recent supported version will be remedied through high priority bug fixes and provided in the Latest Major/Minor Version Release of all currently supported Major Versions of the software and optionally ported to other versions at Kong’s discretion based on the severity and impact of the bug.

* Other bugs as well as feature requests will be assessed for severity and fixes or enhancements applied to versions at Kong’s discretion depending on the impact of the bug. Typically, these types of fixes and enhancements will only be applied to the most recent Minor Version in the most recent Major Version.

Customers with platinum or higher subscriptions may request fixes outside of the above and Kong will assess them at its sole discretion.

### Deprecation guidelines
From time to time as part of the evolution of our products, we deprecate (in other words, remove or discontinue) product features or functionality. 

We aim to provide customers with at least 6 months’ notice of the removal or phasing out of a significant feature or functionality. We may provide less or no notice if the change is necessary for security or legal reasons, though such situations should be rare. We may provide notice in our documentation, product update emails, or in-product notifications if applicable. 

Once we’ve announced we will deprecate a significant feature or functionality, in general, we won’t extend or enhance the feature or functionality.

### Additional terms
- The above is a summary only and is qualified by Kong’s [Support and Maintenance Policy](https://konghq.com/supportandmaintenancepolicy).
- The above applies to Kong standard software builds only.