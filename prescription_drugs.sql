--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT p1.npi, SUM(total_claim_count) AS total_claim_count
FROM prescriber AS p1
JOIN prescription AS p2
USING (npi)
GROUP BY p1.npi
ORDER BY total_claim_count DESC;
--1881634483 (npi), 99707 (total_claim_count)

-- 1.b. Repeat the above, but this time report the 
--nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT p1.npi, 
nppes_provider_first_name, 
nppes_provider_last_org_name, 
specialty_description,
SUM(total_claim_count) AS total_claim_count
FROM prescriber AS p1
JOIN prescription AS p2
ON p1.npi = p2.npi
GROUP BY p1.npi, 
nppes_provider_first_name, 
nppes_provider_last_org_name, 
specialty_description
ORDER BY total_claim_count DESC;
--Bruce Pendley, Family Practice (specialty description) Total Claims 99707

--2.a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT p1.specialty_description, SUM (total_claim_count) AS claims_count
FROM prescriber AS p1
JOIN prescription AS p2
USING (npi)
GROUP BY p1.specialty_description
ORDER BY claims_count DESC;
-- Family Practice 9752347


-- 2.b. Which specialty had the most total number of claims for opioids?

SELECT p1.specialty_description, SUM(total_claim_count) AS claims_count
FROM prescriber AS p1
JOIN prescription AS p2 
USING (npi)
JOIN drug AS d
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY p1.specialty_description
ORDER BY claims_count DESC;
-- Nurse Practitioner 900845


-- 2. c. **Challenge Question:** 
--Are there any specialties that appear in the prescriber table that 
--have no associated prescriptions in the prescription table?

SELECT p1.specialty_description, SUM(p2.total_claim_count) AS claims_count
FROM prescriber AS p1
LEFT JOIN prescription AS p2
ON p1.npi = p2.npi
GROUP BY p1.specialty_description
ORDER BY claims_count DESC;
-- 15


--  d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?

--?


--3. a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, ROUND(SUM(total_drug_cost),2) AS total_drug
FROM drug as d
JOIN prescription AS p
USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug DESC;
-- Insulin 104264066.35

-- 3. b. Which drug (generic_name) has the hightest total cost per day? 
--**Bonus: Round your cost per day column to 2 decimal places. 
--Google ROUND to see how this works.**

SELECT generic_name, ROUND((SUM(total_drug_cost)/SUM(p.total_day_supply)),2) AS daily_c
FROM drug AS d
JOIN prescription AS p
USING(drug_name)
GROUP BY generic_name
ORDER BY daily_c DESC;
-- C1 Esterase Inhibitor 3495.22

--4. a. For each drug in the drug table, return the drug name and then a column 
--named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for 
--those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
	(CASE
		WHEN opioid_drug_flag = 'Y'
	 	THEN 'opioid'
	 	WHEN antibiotic_drug_flag = 'Y'
		THEN 'antibiotic'
	 ELSE 'Neither' END) AS drug_type
FROM drug AS d;


-- 4. b. Building off of the query you wrote for part a, determine whether more was 
--spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT 
(CASE 
WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
 ELSE 'NEITHER' END) AS drug_type, SUM(CAST(total_drug_cost AS MONEY)) AS drug_cost
FROM drug AS d
JOIN prescription AS p
USING (drug_name)
GROUP BY drug_type
ORDER BY drug_cost DESC;
--Neither 2,972,698,710.23, Opioid 105,080,626.37


--5.a. How many CBSAs are in Tennessee? **Warning:** 
--The cbsa table contains information for all states, not just Tennessee.

SELECT DISTINCT cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%';
-- 10


--5. b. Which cbsa has the largest combined population? Which has the smallest? 
--Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS pop
FROM cbsa
JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY pop DESC;
-- Nashville-Davidson-Murfreesboro-Frankling,TN 1830410
-- Morristown, TN 116352


-- 5. c. What is the largest (in terms of population) county which is not included in a CBSA? 
-- Report the county name and population.

SELECT fc.county AS county_name, SUM(p.population) AS pop
FROM population AS p
LEFT JOIN cbsa AS c
USING (fipscounty)
JOIN fips_county AS fc
ON fc.fipscounty = p.fipscounty
WHERE c.fipscounty IS NULL
GROUP BY county_name
ORDER BY pop DESC;
-- SEVIER 95523


-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. 
--Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name, total_claim_count
ORDER BY total_claim_count DESC;
-- OXYCODONE HCL 4538


-- 6. b. For each instance that you found in part a, 
--add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
JOIN drug 
USING (drug_name)
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC;


-- 6. c. Add another column to you answer from the previous part which 
-- gives the prescriber first and last name associated with each row.

SELECT p2.drug_name, total_claim_count, nppes_provider_first_name, 
nppes_provider_last_org_name, 
(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'NO' END) AS opioid
FROM prescriber AS p1
JOIN prescription AS p2
USING (npi)
JOIN drug AS d
USING (drug_name)
WHERE total_claim_count >=3000
ORDER BY total_claim_count DESC;


--7. The goal of this exercise is to generate a full list of all pain management 
--specialists in Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.

--A.
SELECT npi, drug_name
FROM prescriber 
CROSS JOIN drug 
WHERE nppes_provider_city = 'NASHVILLE' 
AND specialty_description LIKE 'Pain Management' AND opioid_drug_flag = 'Y';

--B.
SELECT p1.npi, d.drug_name, total_claim_count
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
ON p1.npi = p2.npi AND d.drug_name = p2.drug_name
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description LIKE 'Pain Management' AND opioid_drug_flag = 'Y'
ORDER BY p1.npi;

--C.
SELECT p1.npi, d.drug_name, COALESCE(total_claim_count,0)
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
ON p1.npi = p2.npi AND d.drug_name = p2.drug_name
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description LIKE 'Pain Management' AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count;









