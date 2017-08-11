select a.*,b.name dep_name
from employees a
left join departments b on b.id=a.department_id

