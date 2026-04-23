## Data Quality Issues Discovered

### Customer Attributes Inconsistency
During cleaning, a critical issue was identified: customer attributes 
(`CustomerID`, `DOB`, `Gender`, `Location`) are **not consistent across transactions**.

The same `CustomerID` appears with different gender, date of birth, 
and location values in different transactions, which indicates this dataset 
was likely **synthetically generated** or contains severe data entry errors.

**Examples:**
- C2715078: DOB appears as both 1994 and 1973, Location as VADODARA and INDORE
- C1731925: Gender appears as both M and F, DOB as both 1983 and 1993

### Decision
Because customer-level attributes are unreliable, **no customer-level 
grouping was used for imputation**. Missing values in `Gender`, `Location`, 
and `DOB` were filled using the **global mode** as a neutral placeholder.

> ⚠️ These columns should not be used as primary dimensions in any 
> customer-level analysis without further data validation.
