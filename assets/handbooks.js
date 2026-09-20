(function () {
  const articles = window.AGRIBASE_CONTENT && window.AGRIBASE_CONTENT.articles;
  if (!articles) return;

  const replace = (slug, title, description, body) => {
    const article = articles.find(item => item.slug === slug);
    if (!article) return;
    article.title = title;
    article.description = description;
    article.body = body;
  };

  replace('prepare-soil-for-vegetables', 'How to Prepare Soil for Vegetables: A Practical Farmer Handbook', 'Prepare vegetable land step by step by checking soil, water, drainage, organic matter, beds and planting readiness.', `
<div class="notice"><strong>How to use this handbook:</strong> Follow the steps in order before planting. Good soil preparation is not adding the most fertilizer. It is making a root zone that has air, water, structure and enough nutrients for the crop. Soil type, rainfall, crop, previous land use and local advice must guide the final decision.</div>
<h2>Contents</h2><ol><li><a href="#plan">Plan the field before working</a></li><li><a href="#sample">Check and test the soil</a></li><li><a href="#clear">Clear weeds and residues safely</a></li><li><a href="#drainage">Check drainage and slope</a></li><li><a href="#organic">Add safe organic matter</a></li><li><a href="#work">Work the soil at the right moisture</a></li><li><a href="#beds">Make beds, paths and irrigation</a></li><li><a href="#planting">Prepare for planting</a></li><li><a href="#mistakes">Common mistakes</a></li><li><a href="#checklist">Final field checklist</a></li></ol>
<h2 id="plan">1. Plan the field before working</h2>
<p>Start with the crop and the market, then plan the soil. List the vegetables you want to grow, the expected planting date, the harvest period, the water source and the size of land. Cabbage, tomato, onion, carrot and leafy vegetables do not need exactly the same bed, spacing or root-zone conditions.</p>
<ol><li>Walk the field and mark high places, low places, wet corners, rocky areas, shade, paths and the water point.</li><li>Find out what was grown there before. Note herbicides, disease, manure, flooding and poor patches.</li><li>Divide the field into uniform areas. Do not treat a sandy upper slope and a wet clay corner as one soil.</li><li>Plan permanent paths so workers and wheelbarrows do not compact the planting beds.</li><li>Decide where clean water will enter and where excess water will leave safely.</li></ol>
<div class="notice"><strong>Farmer rule:</strong> A field that looks the same from the road may have different soil, drainage and fertility inside it. Walk it before spending money on inputs.</div>
<h2 id="sample">2. Check and test the soil</h2>
<p>A soil test is the best starting point for lime and fertilizer decisions. A yellow plant or dark soil colour is not a soil test. Before collecting samples, ask the laboratory which depth, container and tests it requires.</p>
<ol><li>Separate the field by soil colour, slope, crop history, drainage and crop performance.</li><li>Take several small samples from the same depth in a zigzag pattern across each uniform area.</li><li>Avoid manure piles, compost heaps, fertilizer bands, paths, fence lines and unusual patches.</li><li>Mix the ordinary samples in a clean bucket, remove stones and roots, then label field, depth, date, previous crop and intended crop.</li><li>Sample a poor patch separately instead of mixing it with healthy soil.</li></ol>
<p>Check pH, organic matter and the nutrients recommended for your crop. Keep the laboratory report with the farm records. Use the recommendation for lime or fertilizer; do not copy a rate from another farm because the same product behaves differently in different soils.</p>
<h3>Simple field observations</h3><ul><li><strong>Texture:</strong> sandy soil feels gritty and drains quickly; clay feels sticky when wet and can drain slowly; loam is a useful mixture but is not automatically fertile.</li><li><strong>Structure:</strong> crumbly aggregates allow air, water and roots to move. Hard plates, massive clods and a sealed surface show a structure problem.</li><li><strong>Depth:</strong> dig safely in several places and check for rock, hardpan, roots and standing water.</li><li><strong>Moisture:</strong> soil should be workable, not powder-dry and not wet enough to smear.</li></ul>
<h2 id="clear">3. Clear weeds and residues safely</h2>
<p>Remove perennial weeds before making beds. Weeds compete for water and nutrients and can carry pests and diseases. Pulling only the leaves of a deep-rooted weed may allow it to return. Remove roots where practical and prevent mature weeds from producing seed.</p>
<p>Crop residues can protect soil and return organic matter, but diseased material should not be spread into the next vegetable bed. Compost only material that will decompose safely and reach suitable composting conditions. Fresh manure can burn roots, add weed seeds and create food-safety risk; use mature, well-managed manure and follow local waiting requirements.</p>
<ol><li>Remove plastic, wire, stones and woody material that will interfere with tools or irrigation.</li><li>Identify diseased residues and keep them away from clean nursery areas.</li><li>Do not burn valuable healthy residues by default; retain or compost them when safe and useful.</li><li>Control weeds around the field edges and water points so they do not reinvade the beds.</li></ol>
<h2 id="drainage">4. Check drainage and slope</h2>
<p>Vegetable roots need both water and air. Waterlogging removes air from the soil, while very fast drainage can leave roots dry and carry soluble nutrients below the root zone. Walk the land after rain or irrigation and observe where water enters, stands, runs and leaves.</p>
<table><thead><tr><th>What you see</th><th>What to check</th><th>Possible response</th></tr></thead><tbody><tr><td>Water stands after rain</td><td>Compaction, hardpan, blocked outlet, high water table or over-irrigation</td><td>Repair the cause; use raised beds only where they improve drainage.</td></tr><tr><td>Runoff carries soil</td><td>Bare surface, slope, compacted soil or concentrated flow</td><td>Keep soil covered and slow water with suitable contour or grass measures.</td></tr><tr><td>Bed dries very quickly</td><td>Sand, shallow soil, poor root cover or leaking irrigation</td><td>Use mulch, improve organic matter safely and measure irrigation.</td></tr><tr><td>Lower end is always wet</td><td>Field grade and irrigation distribution</td><td>Divide irrigation zones and provide safe drainage where appropriate.</td></tr></tbody></table>
<p>Do not make deep drains, terraces or large earth structures without suitable local design. A badly placed drain can move water and soil into another field.</p>
<h2 id="organic">5. Add safe organic matter</h2>
<p>Organic matter can improve aggregation, water holding, nutrient supply and soil life. It does not replace a soil test and it is not automatically safe because it is natural. Use mature compost, well-managed manure, crop residues or a locally suitable cover crop.</p>
<ol><li>Check the source. Avoid material contaminated with chemicals, plastics, heavy metals, pathogens or excess salts.</li><li>Use mature compost or manure that is dark, stable and no longer heating strongly.</li><li>Apply evenly over the bed area rather than making a concentrated pile beside plants.</li><li>Mix it into the appropriate shallow root zone where local practice supports incorporation, or use it as surface cover.</li><li>Record the source, approximate amount, date and field so crop performance can be reviewed.</li></ol>
<p>Too much manure can add excess phosphorus, salts or nitrogen. Fresh manure in crops eaten raw can create a food-safety problem. Follow local regulations and crop-specific waiting periods.</p>
<h2 id="work">6. Work the soil at the right moisture</h2>
<p>Working wet soil can smear pores and create hard clods. Working very dry clay can break structure into large blocks and consume unnecessary fuel. Take a handful from the intended working depth and squeeze it. If it forms a sticky ribbon or leaves a shiny smear, wait. If it is so dry that it will not hold together at all, avoid aggressive disturbance.</p>
<ol><li>Loosen only as deeply as the crop and soil require. Do not plough repeatedly just because the field is empty.</li><li>Break severe compaction only after confirming a restrictive layer and choosing the right soil moisture.</li><li>Make the surface fine enough for small seed, but do not turn it into powder that will crust after rain.</li><li>Level the bed enough for uniform irrigation, while keeping drainage and slope in mind.</li><li>Leave the field to settle where needed and avoid unnecessary traffic afterward.</li></ol>
<h2 id="beds">7. Make beds, paths and irrigation</h2>
<p>Raised beds can improve drainage and make planting, weeding and harvesting easier. Flat beds can conserve moisture in dry areas. The correct design depends on rainfall, soil, crop, tools and irrigation system.</p>
<ul><li>Make beds wide enough for the crop but narrow enough that the centre can be reached without stepping on it.</li><li>Keep paths clearly marked and use the same paths to protect root zones from compaction.</li><li>Place drip lines, furrows or sprinklers so the whole root zone receives water uniformly.</li><li>Test flow, leaks and blocked emitters before planting.</li><li>Use mulch where suitable, leaving space around stems to reduce rot and pest shelter.</li></ul>
<p>Do not plant until the bed can receive water without flooding, crusting or washing soil away. In sloping land, lay out beds and water movement with local contour guidance.</p>
<h2 id="planting">8. Prepare for planting</h2>
<p>A prepared bed is ready when the soil is workable, the water system is tested, weeds are controlled and the crop has a clear planting plan. Before seed or seedlings enter the field, complete this final sequence:</p>
<ol><li>Confirm the variety, planting date, spacing and expected plant population.</li><li>Mark rows with a rope or measuring stick. Do not let workers estimate spacing by eye.</li><li>Apply only the test-based basal fertilizer or amendment planned for the crop. Keep concentrated fertilizer away from seed and roots.</li><li>Water the bed lightly if needed so seedlings meet moist soil, not dry dust or standing water.</li><li>Transplant healthy, hardened seedlings during a cooler part of the day where possible.</li><li>Water immediately after transplanting and record the date, field, variety and number planted.</li><li>Inspect the field after the first irrigation and correct dry or flooded areas.</li></ol>
<h2 id="mistakes">9. Common soil-preparation mistakes</h2>
<ul><li>Adding fertilizer before testing or diagnosing the soil.</li><li>Working clay while wet and creating a hard layer that roots cannot cross.</li><li>Using fresh manure directly before planting vegetables.</li><li>Making beds without planning paths, drainage and irrigation access.</li><li>Removing every residue, leaving the soil bare and exposed to erosion.</li><li>Planting a crop without checking whether the field had a related disease before.</li><li>Making all beds the same even though water and soil change across the field.</li><li>Ignoring water quality, salinity or a blocked drainage outlet.</li></ul>
<h2 id="checklist">10. Final field checklist</h2>
<div class="notice"><ul><li>[ ] I mapped soil, slope, water and wet areas.</li><li>[ ] I know the previous crop and any herbicide or disease risk.</li><li>[ ] I collected representative soil samples and kept the test report.</li><li>[ ] I removed perennial weeds and managed residues safely.</li><li>[ ] I used mature, safe organic matter and recorded it.</li><li>[ ] I waited until soil moisture was suitable for working.</li><li>[ ] I planned beds, paths, drainage and irrigation together.</li><li>[ ] I tested irrigation before planting.</li><li>[ ] I measured rows and kept fertilizer away from seed and roots.</li><li>[ ] I recorded planting date, variety, spacing, inputs and observations.</li></ul><p><strong>Good vegetable soil preparation is a process.</strong> Observe the land, test where possible, prepare only what is needed, plant carefully and record the result for the next season.</p></div>`);

  replace('tomato-fertilizer-guide', 'Tomato Fertilizer Guide: A Practical Farmer Handbook', 'Feed tomato plants from soil evidence and crop stage while protecting roots, fruit quality, profit and the environment.', `
<div class="notice"><strong>Important:</strong> There is no single tomato fertilizer rate for every farm. Soil test, water quality, variety, yield target, soil texture, irrigation and local product labels must guide the final program. The steps below teach how to make a responsible plan without guessing.</div>
<h2>Contents</h2><ol><li><a href="#before">Before buying fertilizer</a></li><li><a href="#needs">What tomatoes need</a></li><li><a href="#labels">Read the fertilizer label</a></li><li><a href="#plan">Build the feeding plan</a></li><li><a href="#stages">Feed by crop stage</a></li><li><a href="#methods">Choose application method</a></li><li><a href="#symptoms">Read symptoms carefully</a></li><li><a href="#mistakes">Common mistakes</a></li><li><a href="#records">Record every application</a></li><li><a href="#checklist">Final checklist</a></li></ol>
<h2 id="before">1. Before buying fertilizer</h2>
<p>Start by asking what is limiting the crop. A weak tomato plant may be hungry, but it may also have damaged roots, poor drainage, drought, salinity, disease, compaction, cold soil or a pH problem. More fertilizer will not repair every problem.</p>
<ol><li>Take a representative soil sample and request pH, organic matter and nutrient results.</li><li>Test irrigation water where salinity, high bicarbonate or poor infiltration is suspected.</li><li>Write a realistic yield target based on variety, planting date, water and local experience.</li><li>Estimate plant population and field area. A fertilizer rate per plant is not the same as a rate per hectare.</li><li>List the fertilizer already supplied by compost, manure, starter products and irrigation water.</li><li>Check the product label, registration, storage instructions and cost per unit of nutrient.</li></ol>
<p>Keep soil and water reports with the plan. If the crop is already suffering, compare a healthy and poor area, inspect roots and review irrigation before applying a corrective product.</p>
<h2 id="needs">2. What tomatoes need</h2>
<table><thead><tr><th>Nutrient</th><th>Main work in the plant</th><th>When too much or too little causes trouble</th></tr></thead><tbody><tr><td>Nitrogen (N)</td><td>Leaves, stems, chlorophyll and growth.</td><td>Too little gives pale slow growth. Too much gives soft leafy plants, delayed maturity and more pest or disease risk.</td></tr><tr><td>Phosphorus (P)</td><td>Roots, energy transfer, early establishment and reproduction.</td><td>Shortage is worse in cold, wet, compacted or extreme-pH soil. Extra P cannot fix damaged roots.</td></tr><tr><td>Potassium (K)</td><td>Water regulation, sugar movement, fruit filling and plant strength.</td><td>Shortage can cause edge scorch and poor filling. Excess can raise salts or reduce magnesium uptake.</td></tr><tr><td>Calcium (Ca)</td><td>Growing points, roots and cell walls.</td><td>Uneven water supply can cause blossom-end rot even when soil calcium is present.</td></tr><tr><td>Magnesium (Mg)</td><td>Chlorophyll and photosynthesis.</td><td>Shortage often shows as yellow tissue between veins on older leaves; excess potassium can reduce uptake.</td></tr><tr><td>Sulfur and micronutrients</td><td>Protein, enzymes, flowers and plant processes.</td><td>Use a test or qualified diagnosis because symptoms overlap and some micronutrients have a narrow safe range.</td></tr></tbody></table>
<p>Tomato feeding is a balance. Strong growth needs enough nitrogen, but fruiting plants also need a suitable supply of potassium, calcium, magnesium and other nutrients. Water must move nutrients to healthy roots. Roots need oxygen, so fertilizer cannot compensate for waterlogged soil.</p>
<h2 id="labels">3. Read the fertilizer label</h2>
<p>Fertilizer analysis is commonly written as three numbers such as 10-20-20. These numbers show the percentage of nitrogen, available phosphate expressed as P2O5 and soluble potash expressed as K2O. The product may also list sulfur, calcium or micronutrients.</p>
<p>To calculate nutrient supplied, use: <strong>product amount x nutrient percentage = nutrient amount</strong>. For example, 100 kg of a 10-20-20 product contains 10 kg N, 20 kg P2O5 and 20 kg K2O under that label convention. This is a calculation example, not a recommendation to apply that amount to tomatoes.</p>
<ul><li>Check whether the product is granular, soluble, foliar or intended for fertigation.</li><li>Do not assume two products with the same name have the same analysis.</li><li>Compare the price of the nutrient supplied, not only the price of the bag.</li><li>Keep products dry, labelled and away from seed, food, feed and children.</li><li>Never mix products unless the label or qualified local advice confirms compatibility.</li></ul>
<h2 id="plan">4. Build the feeding plan</h2>
<p>Use the 4Rs: the <strong>right source, right rate, right time and right place</strong>. The plan should begin with the soil test and end with a harvest and cost review.</p>
<ol><li><strong>Set the target:</strong> record crop variety, area, plant population, expected yield and market quality.</li><li><strong>Credit the soil:</strong> use soil-test results and previous manure or fertilizer records to estimate what is already available.</li><li><strong>Choose the source:</strong> select a product that supplies the needed nutrient without creating an unwanted salt, chloride, acidity or nutrient imbalance.</li><li><strong>Calculate the rate:</strong> convert the recommendation into product per bed, row, plant or hectare using the label analysis and measured area.</li><li><strong>Split where suitable:</strong> apply large or mobile nutrient amounts in stages when crop demand, soil and irrigation make this practical.</li><li><strong>Place safely:</strong> keep concentrated fertilizer away from seed and stems, and put nutrients where active roots and water can reach them.</li><li><strong>Check the weather:</strong> avoid applying products before runoff, heavy rain or irrigation that will wash them away.</li><li><strong>Review the crop:</strong> compare new growth, roots, leaf colour, flowering and fruit set before changing the plan.</li></ol>
<div class="notice"><strong>Small trial rule:</strong> If the diagnosis is uncertain, test a measured correction on a small marked area and compare it with an untreated area. Record the result before spending on the whole field.</div>
<h2 id="stages">5. Feed by crop stage</h2>
<h3>Stage 1: Nursery and transplanting</h3><p>Seedlings need clean media, light, water and healthy roots. Excess fertilizer in a nursery can burn roots and produce weak, stretched plants. Harden seedlings before transplanting. Use only a suitable starter program from the label or local recommendation, and never place concentrated fertilizer directly against the seedling plug.</p>
<h3>Stage 2: Establishment and early vegetative growth</h3><p>After transplanting, the priority is root-to-soil contact, even moisture and root growth. Apply planned nutrients only when the soil is moist enough for roots to take them up and drainage is adequate. Avoid forcing large leafy growth with nitrogen before the plant has a strong root system.</p>
<h3>Stage 3: Flowering and fruit set</h3><p>Keep water and nutrition steady. Sudden drought followed by heavy irrigation can increase blossom-end rot and fruit cracking. Inspect new leaves, flowers and roots. Do not treat every flower problem with calcium; check irrigation, root health, salinity, pests and disease as well.</p>
<h3>Stage 4: Fruit filling and repeated harvest</h3><p>Fruit load increases nutrient and water demand. Split applications may reduce waste on suitable soils and systems. Maintain balanced nutrition rather than chasing dark green leaves. Stop or adjust feeding according to crop maturity, soil test, local program and the product label.</p>
<h2 id="methods">6. Choose the application method</h2>
<table><thead><tr><th>Method</th><th>Useful when</th><th>Main caution</th></tr></thead><tbody><tr><td>Incorporated basal fertilizer</td><td>Preparing beds before planting.</td><td>Uneven spreading or deep placement can put nutrients away from roots.</td></tr><tr><td>Side-dressing</td><td>Applying measured nutrients beside established rows.</td><td>Keep granules away from stems and water them in safely where appropriate.</td></tr><tr><td>Fertigation</td><td>Splitting soluble nutrients through a suitable irrigation system.</td><td>Requires clean water, compatible products, correct concentration and flushing.</td></tr><tr><td>Foliar feeding</td><td>Small, targeted correction where the product is labelled for the crop.</td><td>Can burn leaves and does not replace a soil or root-zone plan.</td></tr></tbody></table>
<p>Calibrate cups, spreaders, injectors and sprayers. Measure a known area and weigh the product instead of estimating a bag or handful. Check distribution at the beginning, middle and end of beds or irrigation lines.</p>
<h2 id="symptoms">7. Read symptoms carefully</h2>
<p>Older leaves affected first can suggest mobile nutrients such as nitrogen, phosphorus, potassium or magnesium. Young leaves and growing points can suggest calcium, boron, iron, zinc or other less mobile nutrients. These are clues, not proof.</p>
<ul><li><strong>Uniform pale older leaves:</strong> check nitrogen, roots, water and disease.</li><li><strong>Yellow between veins:</strong> check magnesium, iron, manganese, pH and leaf age.</li><li><strong>Leaf-edge scorch:</strong> check potassium, salt, drought and root damage.</li><li><strong>Blossom-end rot:</strong> check uneven moisture, roots, salinity and calcium delivery; do not assume a bag of calcium is the whole answer.</li><li><strong>Dark lush growth with few fruits:</strong> check excess nitrogen, light, temperature, pollination and variety.</li><li><strong>Patchy symptoms:</strong> compare drainage, compaction, irrigation uniformity and soil test results across the field.</li></ul>
<p>Look at roots and soil before adding more product. Disease, insects, herbicide injury, salinity and drought can imitate deficiency.</p>
<h2 id="mistakes">8. Common tomato fertilizer mistakes</h2>
<ul><li>Using a universal calendar rate without a soil test or crop record.</li><li>Applying more nitrogen because plants look small without checking roots or water.</li><li>Putting granular fertilizer against stems, seed or transplant plugs.</li><li>Applying soluble fertilizer before heavy rain or into a waterlogged bed.</li><li>Changing several products at once and then not knowing what helped.</li><li>Ignoring irrigation uniformity and blaming fertilizer for dry or flooded plants.</li><li>Using foliar fertilizer in hot sun or at an unlabelled concentration.</li><li>Failing to record product analysis, rate, area, date and crop response.</li></ul>
<h2 id="records">9. Record every application</h2>
<table><thead><tr><th>Date</th><th>Field and crop stage</th><th>Product and analysis</th><th>Rate and area</th><th>Weather and water</th><th>Result</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>After application, return to the field and record leaf response, flowering, fruit quality, pest or disease pressure and harvest. Compare fertilizer cost with saleable yield, not only with plant colour.</p>
<h2 id="checklist">10. Final tomato fertilizer checklist</h2>
<div class="notice"><ul><li>[ ] I tested soil or have a clear local recommendation.</li><li>[ ] I checked water, drainage, roots and previous inputs.</li><li>[ ] I set a realistic yield target and measured the area.</li><li>[ ] I read the analysis and calculated product amount correctly.</li><li>[ ] I selected the source for the crop and soil, not only the cheapest bag.</li><li>[ ] I applied the right rate, time and place.</li><li>[ ] I kept fertilizer away from seed and stems.</li><li>[ ] I checked irrigation uniformity before blaming nutrition.</li><li>[ ] I recorded every application and crop response.</li><li>[ ] I followed product labels, safety requirements and local advice.</li></ul><p><strong>Good tomato nutrition is measured management.</strong> Feed the root zone according to evidence, keep water steady, watch the crop and learn from the record.</p></div>`);

  replace('farm-record-keeping', 'Farm Record Keeping for Beginners: A Practical Farmer Handbook', 'Build a simple record system for land, inputs, labour, water, harvest, sales, costs and better decisions next season.', `
<div class="notice"><strong>How to use this handbook:</strong> Start with one notebook, a pen and a fixed place to keep it dry. A simple record written every day is more useful than a perfect form that nobody completes. Record facts while they are fresh, then review them every week.</div>
<h2>Contents</h2><ol><li><a href="#why">Why records matter</a></li><li><a href="#setup">Set up your record book</a></li><li><a href="#field">Field and crop records</a></li><li><a href="#inputs">Inputs and stock records</a></li><li><a href="#labour">Labour and equipment</a></li><li><a href="#water">Weather and water</a></li><li><a href="#harvest">Harvest and sales</a></li><li><a href="#money">Cash and costs</a></li><li><a href="#review">Weekly and seasonal review</a></li><li><a href="#mistakes">Common mistakes</a></li><li><a href="#templates">Simple templates</a></li></ol>
<h2 id="why">1. Why records matter</h2>
<p>Farming becomes easier to improve when the farmer can see what happened. Records show how much seed was planted, how much fertilizer was used, how many labour days were paid, how much water was applied, what was harvested, who bought it and whether the crop made money.</p>
<p>Records are not only for large farms. A small vegetable garden can use one page per bed. A livestock farmer can use one page per animal group. The purpose is to replace memory with evidence and to notice problems early enough to act.</p>
<ul><li>Records help you plan the next crop and avoid buying too much or too little.</li><li>Records show which field, variety or input performed best.</li><li>Records support accurate prices, loans, insurance and business discussions.</li><li>Records show the true cost per kilogram or crate.</li><li>Records help identify theft, waste, late work, poor germination and hidden losses.</li></ul>
<h2 id="setup">2. Set up your record book</h2>
<p>Use a notebook with numbered pages, a spreadsheet, or both. Keep the system simple enough to use with dirty hands and limited internet. Use one page for a field map and one section for each record type.</p>
<ol><li>Write the farm name, season and contact details on the first page.</li><li>Give every field, garden bed, animal group and storage area a clear name or number.</li><li>Use one line for one event. Write the date first.</li><li>Record quantities with units such as kg, bags, litres, hours, plants, crates or dollars.</li><li>Keep receipts, invoices and delivery notes in an envelope that matches the notebook.</li><li>Write the record on the same day. If you estimate later, mark it as an estimate.</li></ol>
<div class="notice"><strong>Minimum daily line:</strong> Date | Field or enterprise | What happened | Quantity | Cost or income | Person responsible | Observation.</div>
<h2 id="field">3. Field and crop records</h2>
<p>Give each field a short history. Record area, soil observations, previous crop, planting date, variety, spacing, plant population, irrigation method and problems. This history helps with crop rotation, fertilizer planning and disease prevention.</p>
<table><thead><tr><th>Field</th><th>Area</th><th>Crop and variety</th><th>Planting date</th><th>Spacing</th><th>Water source</th><th>Previous crop</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>During the season, record weeding, fertilizer, spraying, irrigation, scouting, disease, replanting, storms and other important work. Write what you saw, not only what you intended to do.</p>
<h2 id="inputs">4. Inputs and stock records</h2>
<p>Every seed, fertilizer, chemical, feed, fuel and packaging purchase should be recorded. A stock record prevents emergency buying and shows where money is going.</p>
<table><thead><tr><th>Date</th><th>Input</th><th>Supplier</th><th>Quantity bought</th><th>Unit cost</th><th>Quantity used</th><th>Balance</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>For crop protection products, also record product name, formulation, crop, target problem, label rate, date, operator, protective equipment and pre-harvest interval. Store products locked, labelled and away from food and feed.</p>
<h2 id="labour">5. Labour and equipment</h2>
<p>Labour records show how many hours or workdays each activity required. This matters even when family labour is unpaid because it has a real value and may be needed in the next budget.</p>
<table><thead><tr><th>Date</th><th>Field</th><th>Task</th><th>People</th><th>Hours or days</th><th>Rate</th><th>Total</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>Record tractor hours, fuel, repairs, hired equipment and tool loss. A machine that works for ten hours is not free just because the farmer owns it. Include fuel, maintenance and a reasonable equipment cost when comparing enterprises.</p>
<h2 id="water">6. Weather and water</h2>
<p>Write down daily rainfall when possible, irrigation dates, run time, estimated volume, pump hours, leaks, dry spells and water problems. Also record heat, strong wind, frost, hail, flooding and unusual weather. Weather notes help explain poor germination, disease, fruit cracking, drought stress and harvest delays.</p>
<table><thead><tr><th>Date</th><th>Rain</th><th>Irrigation</th><th>Pump or system hours</th><th>Soil and crop observation</th><th>Action</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>Do not use a fixed watering calendar without checking the root zone. A water record becomes useful when it is compared with soil moisture, crop stage and yield.</p>
<h2 id="harvest">7. Harvest and sales</h2>
<p>Harvest records should separate what was picked from what was saleable. Record grade, damaged produce, home use, livestock feed, storage loss, buyer, price and payment date. This shows where income is being lost.</p>
<table><thead><tr><th>Date</th><th>Field and crop</th><th>Harvested</th><th>Grade 1</th><th>Grade 2</th><th>Rejected or used</th><th>Buyer and price</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>Count the weight at the field and again at the buyer where possible. Keep delivery notes and record unpaid sales as money still owed, not as cash already received.</p>
<h2 id="money">8. Cash and costs</h2>
<p>Separate money paid out from money received. Record household withdrawals and farm cash separately. Mixing them makes it impossible to know whether the farm made a profit or whether farm cash was used for another purpose.</p>
<table><thead><tr><th>Date</th><th>Description</th><th>Money in</th><th>Money out</th><th>Payment method</th><th>Receipt or note</th><th>Balance</th></tr></thead><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<p>At the end of the crop, calculate: <strong>revenue = saleable quantity x selling price</strong>. Then compare revenue with seed, fertilizer, chemicals, labour, water, fuel, transport, packaging, rent, repairs and other costs. Keep unpaid family labour and owned equipment visible as estimated costs when making a serious business decision.</p>
<h2 id="review">9. Review every week and every season</h2>
<h3>Weekly review</h3><ol><li>Check which planned activities were completed.</li><li>Compare actual input use and spending with the budget.</li><li>Check stock, cash, crop condition, water and labour availability.</li><li>Write the three biggest problems and the next action for each.</li><li>Update the next seven days so work is done on time.</li></ol>
<h3>End-of-season review</h3><ul><li>What was the total saleable harvest and average price?</li><li>Which costs were higher or lower than planned?</li><li>Which field, variety, supplier or method performed best?</li><li>Where did labour, water, pests, disease or market timing reduce profit?</li><li>What should be repeated, stopped or tested next season?</li></ul>
<table><thead><tr><th>Planned</th><th>Actual</th><th>Difference</th><th>Why was it different?</th><th>Next action</th></tr><tbody><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr><tr><td>________</td><td>________</td><td>________</td><td>________</td><td>________</td></tr></tbody></table>
<h2 id="mistakes">10. Common record-keeping mistakes</h2>
<ul><li>Waiting until the end of the season and trying to remember.</li><li>Writing quantities without units.</li><li>Recording only purchases but not what was used in each field.</li><li>Counting all harvest as saleable and ignoring grading or waste.</li><li>Ignoring family labour, equipment, transport and unpaid credit.</li><li>Mixing household cash with farm cash.</li><li>Keeping records in a phone that is not backed up or a notebook exposed to rain.</li><li>Recording a plan as if it already happened.</li></ul>
<h2 id="templates">11. A simple daily page</h2>
<div class="notice"><p><strong>Date:</strong> ____________________ &nbsp; <strong>Weather:</strong> ____________________</p><p><strong>Field or enterprise:</strong> ____________________ &nbsp; <strong>Crop or animals:</strong> ____________________</p><p><strong>Work completed:</strong> ____________________________________________________</p><p><strong>Inputs or labour used:</strong> ______________________________________________</p><p><strong>Quantity and cost:</strong> __________________________________________________</p><p><strong>What I observed:</strong> ___________________________________________________</p><p><strong>Next action and date:</strong> _______________________________________________</p></div>
<h2>Final message</h2><p>Good records do not need difficult language or expensive software. Write the date, place, activity, quantity, cost and observation. Review the page every week. After harvest, use the evidence to make the next crop more organised, more profitable and less wasteful.</p>`);

  replace('farming-dry-conditions', 'Farming in Dry Conditions: The Complete Practical Farmer Handbook', 'A complete, step-by-step practical guide to profitable farming in drought-prone areas: soil water retention, tie ridging, Pfumvudza/Zai basins, rainwater harvesting, certified seed, crop rotation, drought-resistant varieties, and enterprise diversification.', `
<div class="notice"><strong>How to use this handbook:</strong> Dryland farming is not about "hoping for rain." It is a disciplined system of capturing every drop of rainfall, preventing soil evaporation, choosing climate-matched seeds, and diversifying farm enterprises so your farm makes a consistent profit even in low-rainfall seasons.</div>
<h2>Contents</h2><ol><li><a href="#reality">1. The Reality of Dryland Farming & The Profit Principle</a></li><li><a href="#soil-moisture">2. Soil Moisture Conservation & In-Field Water Harvesting</a></li><li><a href="#water-catchment">3. Farm Water Catchment & Storage Infrastructure</a></li><li><a href="#crop-choice">4. Selecting Drought-Resistant Crops & Varieties</a></li><li><a href="#certified-seeds">5. Certified Seed vs Saved Seed: Mitigating Risk in Dry Soils</a></li><li><a href="#crop-rotations">6. Crop Rotation & Legume Intercropping Systems</a></li><li><a href="#soil-fertility">7. Organic Matter, Biochar & Micro-Dosing Fertilization</a></li><li><a href="#mixed-farming">8. Mixed Farming & Enterprise Diversification</a></li><li><a href="#pest-weed">9. Weed, Pest & Disease Management under Thermal Stress</a></li><li><a href="#post-harvest">10. Post-Harvest Preservation & Market Timing</a></li><li><a href="#checklist">11. Dryland Farmer Action Checklist</a></li></ol>

<h2 id="reality">1. The Reality of Dryland Farming & The Profit Principle</h2>
<p>Dry conditions, erratic rainfall, and mid-season dry spells are no longer unexpected emergencies—they are the normal reality for millions of farmers across arid and semi-arid regions. Continuing to farm dry land using wet-zone practices (ploughing every year, planting late-maturing uncertified maize, broadcasting fertilizer on dry soil, and relying on single crops) guarantees crop failure and financial loss.</p>
<p>To make farming in dry conditions profitable, every farmer must operate under <strong>Three Fundamental Rules of Dryland Agriculture:</strong></p>
<ol>
  <li><strong>Capture Every Drop:</strong> Treat your field surface like a sponge. Never allow rainwater to run off into ditches or roads; capture it where it falls.</li>
  <li><strong>Stop Soil Evaporation:</strong> Bare soil loses up to 70% of its moisture directly into the hot air through evaporation. Keep the soil covered with mulch or crop canopy at all times.</li>
  <li><strong>Diversify to Protect Cash Flow:</strong> Never rely on a single crop or enterprise. Combine short-season grains, drought-hardy legumes, root crops, and livestock so that even if one crop experiences stress, other enterprises bring in income.</li>
</ol>

<h2 id="soil-moisture">2. Soil Moisture Conservation & In-Field Water Harvesting</h2>
<p>The first reservoir on any farm is the soil root zone. Before spending money on expensive pumps or dams, implement these field-proven soil moisture harvesting structures:</p>

<h3>A. Tie Ridging & Furrow Dyking</h3>
<p>Tie ridging creates a grid of small earth dams across your crop rows. Regular ridges let rainwater run down the furrows and off the field. Tie ridges block the furrow with cross-earthen ties every 1.5 to 3 metres.</p>
<ul>
  <li><strong>How to build tie ridges:</strong> Construct standard contour ridges across the field slope. Dig small earthen mounds (ties) across the furrows connecting adjacent ridges, making the ties about half the height of the main ridge.</li>
  <li><strong>Why it works:</strong> Rainwater is trapped in small basins between the crop rows, forcing water to soak deep into the root zone instead of washing away topsoil.</li>
  <li><strong>Result:</strong> Crops survive mid-season dry spells 14 to 21 days longer than crops planted on flat or un-tied land.</li>
</ul>

<h3>B. Zai Pits & Planting Basins (Pfumvudza / Intwasa System)</h3>
<p>Planting basins (known as Zai pits in West Africa and Pfumvudza/Intwasa in Southern Africa) concentrate water and organic nutrients directly into micro-basins where seeds are planted.</p>
<ol>
  <li><strong>Basin Dimensions:</strong> Dig precise basins measuring 15 cm long, 15 cm wide, and 15 cm deep (or 30 cm long x 15 cm wide x 15 cm deep for maize/sorghum), spaced at 60 cm intra-row and 75 cm to 90 cm inter-row.</li>
  <li><strong>Nutrient Placement:</strong> Place a handful of well-rotted kraal manure or compost (approx. 500g per basin) plus a targeted micro-dose of basal fertilizer (e.g. 5g of Compound D/NPK) at the bottom of each basin.</li>
  <li><strong>Soil Backfill:</strong> Cover the nutrients with a thin layer of clean soil (2-3 cm) before planting seeds. This prevents direct fertilizer burn on seeds while placing plant food directly where roots expand.</li>
  <li><strong>Moisture Capture:</strong> Rainwater collects inside the basin micro-depression, keeping the seedling root zone damp even after light showers.</li>
</ol>

<h3>C. Contour Bunds, Swales & Stone Lines</h3>
<p>On sloping land, uncontrolled water flow cuts gullies and strips fertile topsoil. Siting contour structures along key elevation lines slows water velocity and recharges underground water tables:</p>
<ul>
  <li><strong>Stone Lines (Diguettes):</strong> In rocky areas, lay lines of stones 20-30 cm high along natural contours. Stone lines slow down runoff, trap silt, and allow water to seep into the soil without washing away.</li>
  <li><strong>Dead Level Contours (Swales):</strong> Excavate trenches along exact contour lines (0% slope) with the dug earth mounded on the downslope side. Plant vetiver grass or fodder trees (e.g. Leucaena or Bana grass) on the bank to stabilize soil.</li>
</ul>

<h3>D. Organic Mulching & Crop Canopy Cover</h3>
<p>Mulching is the single most effective way to lower soil temperatures and stop moisture evaporation:</p>
<ul>
  <li>Cover bare soil beds with a 5-10 cm layer of dry grass, crop stalks, maize stover, or dry leaves.</li>
  <li>Soil under mulch stays 5°C to 10°C cooler than bare soil during hot afternoons, preserving root vitality.</li>
  <li>Mulch prevents soil crusting after heavy downpours, ensuring subsequent rainfall infiltrates easily.</li>
</ul>

<h3>E. Minimum Tillage & Conservation Agriculture</h3>
<p>Repeated deep disc ploughing destroys soil aggregation, burns organic matter, and forms a hard pan that prevents roots from tapping deep moisture. Shift to minimum tillage by disturbing only the planting line or basin while leaving the remaining soil covered and undisturbed.</p>

<h2 id="water-catchment">3. Farm Water Catchment & Storage Infrastructure</h2>
<p>Capturing surface runoff during heavy storms gives your farm supplemental water for nursery beds, high-value vegetables, or livestock during dry periods.</p>

<h3>A. Roof Rainwater Harvesting</h3>
<p>Every square metre of corrugated iron roof yields 1 litre of clean water for every 1 mm of rain. A 100 m² roof receives 50,000 litres of water in a 500 mm rainfall season.</p>
<ul>
  <li>Fit wide PVC or zinc gutters with leaf guards along all farm building roofs.</li>
  <li>Direct flow into a first-flush diverter (to discard dusty initial roof wash) before filling plastic storage tanks or brick masonry cisterns.</li>
  <li>Store harvested water tightly covered to eliminate mosquito breeding and algae growth.</li>
</ul>

<h3>B. Earth Dams, Water Pans & Farm Ponds</h3>
<p>Excavated farm ponds (water pans) collect surface runoff from natural drainage paths, farm roads, or contour outlets:</p>
<ol>
  <li><strong>Siting:</strong> Locate ponds on low ground downstream of clean catchments (avoid areas where livestock dung or septic systems contaminate water).</li>
  <li><strong>Excavation & Sizing:</strong> Excavate trapezoidal ponds 2.5 to 3.5 metres deep to minimize surface evaporation area while maximizing volume.</li>
  <li><strong>Sealing:</strong> Compact a 20 cm layer of heavy clay on the pond bottom, or line with a 0.5 mm to 1.0 mm UV-resistant HDPE geomembrane plastic liner to stop seepage losses in sandy soils.</li>
  <li><strong>Silt Traps:</strong> Always construct a shallow sediment basin (silt trap) upstream of the pond so muddy water settles out silt before clean water flows into the main pond.</li>
</ol>

<h3>C. Drip Irrigation & Micro-Watering Efficiency</h3>
<p>Flood irrigation and overhead sprinklers lose 40% to 60% of water to evaporation and wind drift in hot, dry environments. Drip irrigation delivers water directly to the plant root zone with over 90% efficiency:</p>
<ul>
  <li><strong>Low-Head Gravity Drip Kits:</strong> Use 200-litre drums elevated 1.5 to 2 metres high to power gravity drip lines over vegetable beds.</li>
  <li><strong>Sub-Surface Clay Pot (Olla) Irrigation:</strong> Bury unglazed, porous earthenware clay pots neck-deep near fruit trees or crop beds. Fill the pot with clean water and seal the lid. Water seeps slowly through the porous clay walls directly into surrounding soil as roots need it, with zero evaporation.</li>
</ul>

<h2 id="crop-choice">4. Selecting Drought-Resistant Crops & Varieties</h2>
<p>Growing water-hungry varieties in semi-arid zones is the leading cause of farm bankruptcy. Switch your primary cropping plan to crops and varieties evolved for heat and water scarcity:</p>

<table>
  <thead>
    <tr>
      <th>Crop Category</th>
      <th>Recommended Drought-Resistant Crops</th>
      <th>Key Advantages in Dry Conditions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Small Grains</strong></td>
      <td>White & Red Sorghum, Pearl Millet (Mhunga), Finger Millet (Rapoko)</td>
      <td>Deep extensive root systems; ability to go dormant during dry spells and resume growth when rain falls; minimal water requirement compared to maize.</td>
    </tr>
    <tr>
      <td><strong>Legumes & Pulses</strong></td>
      <td>Cowpeas (Nhemba), Groundnuts (Nzungu), Bambara Groundnut (Nyimo), Pigeon Pea</td>
      <td>Fixes atmospheric nitrogen into soil; produces high-protein grain and nutritious livestock residue; thrives in sandy, low-fertility soils.</td>
    </tr>
    <tr>
      <td><strong>Roots & Tubers</strong></td>
      <td>Cassava, Orange-Fleshed Sweet Potato (OFSP), Drought-Tolerant Yams</td>
      <td>Stores energy underground; can remain in the soil for months until needed; highly resilient to erratic rainfall.</td>
    </tr>
    <tr>
      <td><strong>Cash & Oilseed Crops</strong></td>
      <td>Sunflower, Sesame (Simsim), Cotton, Castor Bean</td>
      <td>Deep taproots extract subsoil moisture; high market value per kilogram; resistant to high heat.</td>
    </tr>
    <tr>
      <td><strong>Early Maize Hybrids</strong></td>
      <td>Ultra-short season certified maize hybrids (70–90 days maturity)</td>
      <td>Escapes late-season drought by flowering and maturing before seasonal rains end.</td>
    </tr>
  </tbody>
</table>

<div class="notice"><strong>Farmer Golden Rule:</strong> Never devote 100% of your arable field to maize in dry regions. A resilient dryland farm allocates at least 60% to small grains (sorghum/millet) and legumes (cowpea/groundnut), keeping maize to small, highly-fertilized, moisture-conserved plots (e.g. Pfumvudza basins).</div>

<h2 id="certified-seeds">5. Certified Seed vs Saved Seed: Mitigating Risk in Dry Soils</h2>
<p>When soil moisture is scarce, seed quality determines whether a crop emerges in 4 days or rots in the ground. Planting uncertified grain-bin seed in dry conditions is a high-risk gamble that frequently fails.</p>

<h3>A. Why Certified Seed Pays Off in Dry Conditions</h3>
<ul>
  <li><strong>High Germination Rate (&gt;90%):</strong> Certified seed guarantees vigor. Uniform emergence ensures a complete plant stand before soil surface moisture dries out.</li>
  <li><strong>Purity & Disease Resistance:</strong> Certified seeds are screened for seed-borne fungal pathogens and treated with protective fungicide/insecticide dressings.</li>
  <li><strong>Drought-Escaping Genetics:</strong> Hybrid and open-pollinated certified seeds are bred for specific maturity days (early vs medium) and heat tolerance.</li>
</ul>

<h3>B. Dangers of Uncertified / Grain-Bin Seed</h3>
<ol>
  <li><strong>Hybrid Segregation (F2 generation):</strong> Saved seed from hybrid crops (like F1 maize) loses genetic vigor, yielding 30% to 50% less and segregating into weak, non-uniform plants.</li>
  <li><strong>Low Vigor & Seedling Rot:</strong> Uncertified seed often has micro-cracks or fungal infection. If dry soil delays germination by 3 days, uncertified seed rots underground, forcing expensive replanting.</li>
</ol>

<h3>C. Seed Priming & Hydration Techniques</h3>
<p>To speed up emergence in dry seedbeds, practice <strong>on-farm seed priming:</strong></p>
<ul>
  <li>Soak cereal seeds (sorghum, millet, maize) in clean water for 8 to 10 hours (overnight) before sowing.</li>
  <li>Remove seeds, drain thoroughly, surface-dry in the shade for 1 hour, and plant immediately into moist soil beds.</li>
  <li>Primed seeds absorb initial water, accelerating germination by 2 to 3 days and giving crops a head start against weeds.</li>
</ul>

<h2 id="crop-rotation">6. Crop Rotation & Legume Intercropping Systems</h2>
<p>Monoculture (planting the same crop on the same field year after year) depletes soil nutrients, increases parasitic weeds like Striga (witchweed), and worsens drought damage.</p>

<h3>A. The Cereal-Legume Rotation Cycle</h3>
<p>Rotate heavy-feeding cereal crops with nitrogen-fixing legumes over a 3 to 4-year cycle:</p>

<table>
  <thead>
    <tr>
      <th>Year / Season</th>
      <th>Field Block A</th>
      <th>Field Block B</th>
      <th>Field Block C</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Year 1</strong></td>
      <td>Legumes (Cowpea / Groundnut)</td>
      <td>Sorghum / Pearl Millet</td>
      <td>Cassava / Sweet Potato</td>
    </tr>
    <tr>
      <td><strong>Year 2</strong></td>
      <td>Sorghum / Pearl Millet</td>
      <td>Cassava / Sweet Potato</td>
      <td>Legumes (Cowpea / Groundnut)</td>
    </tr>
    <tr>
      <td><strong>Year 3</strong></td>
      <td>Cassava / Sweet Potato</td>
      <td>Legumes (Cowpea / Groundnut)</td>
      <td>Sorghum / Pearl Millet</td>
    </tr>
  </tbody>
</table>

<h3>B. Legume Intercropping & Biological Cover</h3>
<p>Planting legumes (e.g. Cowpeas, Groundnuts, or Pigeon Pea) between rows of Sorghum or Maize provides multiple benefits:</p>
<ul>
  <li><strong>Ground Cover:</strong> Legume foliage creates a living green carpet that shades the soil, suppressing weeds and lowering soil evaporation.</li>
  <li><strong>Nitrogen Fixation:</strong> Legume root nodules convert air nitrogen into plant food, benefiting current and subsequent cereal crops.</li>
  <li><strong>Push-Pull Pest Management:</strong> Intercropping cereals with Desmodium legume repels stem borer moths ("push") while attraction borders of Napier grass trap pests ("pull").</li>
</ul>

<h2 id="soil-fertility">7. Organic Matter, Biochar & Micro-Dosing Fertilization</h2>
<p>Fertilizer applied incorrectly in dry soils can "burn" crops. Dryland soil fertility requires building organic matter and placing fertilizer with surgical precision.</p>

<h3>A. Building Soil Organic Matter & Pit Composting</h3>
<p>Soil organic matter acts like a giant underground sponge. Every 1% increase in soil organic matter enables soil to hold an extra 150,000 litres of water per hectare!</p>
<ul>
  <li><strong>Dry-Zone Pit Composting:</strong> Excavate compost pits 1 metre deep under shade. Layer crop stalks, animal dung, ash, green leaves, and soil. Add water during building and cover with a 10 cm soil cap to trap heat and moisture. Turn the heap after 4 weeks; mature compost is ready in 8 to 12 weeks.</li>
  <li>Apply 5 to 10 tonnes of well-rotted manure or compost per hectare during bed preparation.</li>
</ul>

<h3>B. Biochar Application</h3>
<p>Biochar (crushed charcoal produced by low-oxygen burning of agricultural residues) is porous and permanent:</p>
<ul>
  <li>Incorporate finely crushed biochar (mixed with compost or manure) into planting basins or root zones.</li>
  <li>Biochar holds water and nutrient ions in its microscopic pores for decades, preventing fertilizer leaching and improving drought resilience in sandy soils.</li>
</ul>

<h3>C. Micro-Dosing Fertilization</h3>
<p>Broadcasting granular fertilizer across dry fields wastes money and damages crops if rain fails. Practice <strong>fertilizer micro-dosing:</strong></p>
<ol>
  <li><strong>Basal Micro-Dosing:</strong> Apply a measured bottle-cap dose (approx. 3g to 5g per plant) of Compound NPK fertilizer directly into the planting basin or furrow, 5 cm beside and below the seed.</li>
  <li><strong>Top-Dressing Micro-Dosing:</strong> Apply a measured cap of Ammonium Nitrate or CAN directly at the base of established plants only when soil is moist following a rain event.</li>
  <li><strong>Efficiency Gain:</strong> Micro-dosing uses 50% to 60% less total fertilizer while delivering higher yields than traditional broadcasting.</li>
</ol>

<h2 id="mixed-farming">8. Mixed Farming & Enterprise Diversification</h2>
<p>Commercial survival in dry regions depends on combining crops with livestock and alternative income enterprises. If a severe mid-season drought reduces crop grain yield, livestock and alternative enterprises secure household income.</p>

<h3>A. Small Livestock Integration</h3>
<p>Small ruminants and poultry thrive in dry environments where large cattle struggle:</p>
<ul>
  <li><strong>Indigenous Goats & Sheep:</strong> Goats browse on deep-rooted acacia bushes and drought shrubs. They reproduce rapidly and provide quick cash sales, milk, and valuable kraal manure.</li>
  <li><strong>Indigenous Poultry & Turkeys:</strong> Hardy local chicken breeds (e.g. Boschveld, Roadrunner) forage for insects and seeds, requiring minimal expensive commercial feed.</li>
  <li><strong>Rabbit Production:</strong> Quiet, fast-breeding small stock that consume weeds and produce nutrient-rich manure for vegetable beds.</li>
</ul>

<h3>B. Fodder Production & Emergency Feed Storage</h3>
<p>Never allow livestock to starve during the dry season. Preserve green fodder when feed is abundant:</p>
<ul>
  <li><strong>Hay Making:</strong> Cut natural grasses (e.g. Rhodes grass, Star grass) at early flowering stage. Sun-cure for 1-2 days in thin layers, bale or stack under a dry shed.</li>
  <li><strong>Pit Silage:</strong> Chop green maize stover, sorghum, or Bana grass into 2 cm pieces. Pack tightly in underground plastic-lined trench pits, compact thoroughly to exclude air, and seal with soil. Silage provides succulent green feed 6 months later during peak drought.</li>
  <li><strong>Fodder Trees:</strong> Plant drought-hardy fodder trees (e.g. <em>Leucaena leucocephala</em>, <em>Calliandra</em>, <em>Gliricidia</em>, or spineless cactus) along fence lines for green protein browse.</li>
</ul>

<h3>C. Apiculture (Beekeeping)</h3>
<p>Beekeeping requires no land ownership, zero daily feeding costs, and generates high-value honey and beeswax in dry acacia bushlands. Bees also improve crop pollination and increase pulse/seed yields.</p>

<h2 id="pest-weed">9. Weed, Pest & Disease Management under Thermal Stress</h2>

<h3>A. Early & Aggressive Weeding</h3>
<p>Weeds are water thieves! A single large pigweed or blackjack consumes up to 4 times more soil water than a young sorghum plant. Weed your field during the first 14 to 21 days after emergence when weeds are small. Never allow weeds to flowering stage.</p>

<h3>B. Managing Drought-Favored Pests</h3>
<p>Hot, dry weather triggers severe outbreaks of specific sap-sucking and leaf-eating pests:</p>
<table>
  <thead>
    <tr>
      <th>Pest</th>
      <th>Drought Damage Symptom</th>
      <th>Practical Control Strategy</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Red Spider Mite</strong></td>
      <td>Fine webbing, yellow stippling on leaf undersides; leaves turn bronze and dry up.</td>
      <td>Avoid dusty field edges; spray overhead water or neem oil/soapy water sprays early in morning.</td>
    </tr>
    <tr>
      <td><strong>Aphids</strong></td>
      <td>Curled leaf tips, sticky honeydew, black sooty mold growth.</td>
      <td>Preserve natural predators (ladybirds, lacewings); spray wood ash water or botanical insecticidal soaps.</td>
    </tr>
    <tr>
      <td><strong>Fall Armyworm & Stem Borer</strong></td>
      <td>Window-pane feeding marks and frass in crop whorls.</td>
      <td>Drop fine sand mixed with wood ash or dry Bacillus thuringiensis (Bt) dust directly into plant whorls.</td>
    </tr>
    <tr>
      <td><strong>Termites</strong></td>
      <td>Severed plant stems at ground level during dry spells.</td>
      <td>Keep organic mulch on soil surface (termites eat mulch instead of living stems); locate and destroy queen mounds.</td>
    </tr>
  </tbody>
</table>

<h2 id="post-harvest">10. Post-Harvest Preservation & Market Timing</h2>
<p>Growing a crop in dry conditions is only half the battle. Losing 30% of harvested grain to grain borers and weevils in storage destroys farm profits.</p>

<h3>A. Proper Field Drying & Curing</h3>
<ul>
  <li>Harvest grain heads (sorghum, millet, maize) when fully mature and cobs/panicles turn dry.</li>
  <li>Dry harvested grain on clean raised drying racks or tarpaulins off the bare ground until grain moisture drops below 12% (kernel snaps crisply when bitten).</li>
</ul>

<h3>B. Hermetic Storage Bags & Zero-Chemical Protection</h3>
<p>Traditional chemical dusts can lose potency or pose health risks if consumed early. Use **Hermetic Triple-Layer Storage Bags (e.g. PICS bags):**</p>
<ol>
  <li>Pack clean, dry grain into the inner high-density polyethylene liner bags and tie tightly.</li>
  <li>Hermetic sealing starves insects and weevils of oxygen. Within 5 days, all insects and eggs suffocate naturally without any chemical dust.</li>
  <li>Grain remains pristine for 1 to 2 years, allowing you to hold grain safely until market prices rise.</li>
</ol>

<h3>C. Market Timing & Value Addition</h3>
<p>Never sell all your grain at harvest peak (May to July) when local supply is high and prices are lowest. Store grain safely until the dry season (October to January) when grain prices double or triple. Add value by milling sorghum/millet into packaged flour or pressing oilseeds (sunflower/sesame) for local sales.</p>

<h2 id="checklist">11. Dryland Farmer Action Checklist</h2>

<div class="notice">
  <h3>Pre-Season Planning (2 Months Before Rains)</h3>
  <ul>
    <li>[ ] I mapped my field contours and laid out dead-level ridges or stone lines.</li>
    <li>[ ] I dug planting basins (Zai/Pfumvudza) or constructed tie ridges across all crop rows.</li>
    <li>[ ] I collected and applied mature compost/manure into planting basins or beds.</li>
    <li>[ ] I purchased certified short-season or drought-resistant seeds (sorghum, millet, cowpea, early hybrid maize).</li>
    <li>[ ] I cleaned water gutters, roof tanks, and desilted farm water ponds.</li>
  </ul>

  <h3>In-Season Management (Planting through Harvest)</h3>
  <ul>
    <li>[ ] I primed seeds (soaked overnight) where suitable before sowing into moist soil.</li>
    <li>[ ] I applied fertilizer via precise micro-dosing directly near plant root zones.</li>
    <li>[ ] I weeded early (within 14–21 days) to prevent weeds from stealing soil water.</li>
    <li>[ ] I applied organic mulch (5–10 cm) to cover bare soil and cut evaporation.</li>
    <li>[ ] I scouted weekly for red spider mites, aphids, and armyworms.</li>
  </ul>

  <h3>Post-Harvest & Marketing</h3>
  <ul>
    <li>[ ] I dried grain thoroughly on raised racks to &lt;12% moisture content.</li>
    <li>[ ] I stored grain in hermetic PICS bags to prevent weevil damage without chemicals.</li>
    <li>[ ] I preserved crop stover, made hay, or sealed silage for livestock dry-season feed.</li>
    <li>[ ] I stored a portion of grain for strategic sale during dry-season peak prices.</li>
  </ul>
</div>

<p><strong>Final Message:</strong> Farming in dry conditions is not a curse—it is a specialized business system. By harvesting every drop of rainwater, building soil organic matter, planting certified drought-resistant crops, and combining livestock with crops, your farm will remain productive, profitable, and resilient every season.</p>
`);

})();
