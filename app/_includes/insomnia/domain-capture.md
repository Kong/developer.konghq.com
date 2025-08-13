Use domain capture to automatically add new users to your Insomnia Enterprise account when they sign up with a verified email domain.
To enable domain capture and auto-capture all new employees:
1. Add and verify a [domain](https://app.insomnia.rest/app/enterprise/domains/list).
1. In the domain settings, click the toggle to enable domain capture.

{:.info}
> You can enable domain capture on a verified domain only.

When you enable domain capture on a verified domain, all new users that create an Insomnia account with an email address in the domain are automatically added to the Enterprise account. For example:

- Kong uses `@kong.com` and enables domain capture: When Amal@kong.com signs up for Insomnia, the platform automatically adds Amal@kong.com to the Enterprise license and lists the user on the licenses page.

{:.warning}
> If you add a new user to your Insomnia Enterprise account with no license seats left in your Enterprise plan, then the new user won't be able to create an account with that domain. To increase the number of seats that you have access to, [update your subscription](/insomnia/accounts/#how-do-i-increase-the-number-of-seats-on-my-team).